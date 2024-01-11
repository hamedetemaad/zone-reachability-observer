#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>
#include "maps.bpf.h"

#define ETH_P_IPV6 0x86DD
#define ETH_P_IP 0x0800

struct ipv4_key_t {
    u32 addr;
};

struct ecn_key_t {
    u32 addr;
};

struct hdr_cursor {
    void *pos;
};

struct {
    __uint(type, BPF_MAP_TYPE_LRU_HASH);
    __uint(max_entries, 1024);
    __type(key, struct ipv4_key_t);
    __type(value, u64);
} xdp_incoming_packets_total SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_LRU_HASH);
    __uint(max_entries, 1024);
    __type(key, struct ecn_key_t);
    __type(value, u64);
} xdp_incoming_ecn_total SEC(".maps");


// Primitive header extraction macros. See xdp-tutorial repo for more robust parsers:
// * https://github.com/xdp-project/xdp-tutorial/blob/master/common/parsing_helpers.h
#define parse_args struct hdr_cursor *cursor, void *data_end, struct
#define parse_header(type)                                                                                             \
    static bool parse_##type(parse_args type **hdr)                                                                    \
    {                                                                                                                  \
        size_t offset = sizeof(**hdr);                                                                                 \
                                                                                                                       \
        if (cursor->pos + offset > data_end) {                                                                         \
            return false;                                                                                              \
        }                                                                                                              \
                                                                                                                       \
        *hdr = cursor->pos;                                                                                            \
        cursor->pos += offset;                                                                                         \
                                                                                                                       \
        return true;                                                                                                   \
    }

parse_header(ethhdr);
parse_header(iphdr);
//parse_header(ipv6hdr);

static int xdp_trace(struct xdp_md *ctx)
{
    void *data_end = (void *) (long) ctx->data_end;
    void *data = (void *) (long) ctx->data;
    struct ipv4_key_t key = {};
    struct ecn_key_t ecn = {};
    struct hdr_cursor cursor = { .pos = data };
    struct ethhdr *eth_hdr;
    struct iphdr *ip_hdr;
    //struct ipv6hdr *ipv6_hdr;

    if (!parse_ethhdr(&cursor, data_end, &eth_hdr)) {
        return XDP_PASS;
    }

    switch (eth_hdr->h_proto) {
    case bpf_htons(ETH_P_IP):
        if (!parse_iphdr(&cursor, data_end, &ip_hdr)) {
            return XDP_PASS;
        }

        key.addr = ip_hdr->saddr;
        increment_map(&xdp_incoming_packets_total, &key, 1);
        if ((ip_hdr->tos & 0x03) == 3) {
          ecn.addr = ip_hdr->saddr;
          increment_map(&xdp_incoming_ecn_total, &ecn, 1);
        }

        break;
    case bpf_htons(ETH_P_IPV6):
        /*
        if (!parse_ipv6hdr(&cursor, data_end, &ipv6_hdr)) {
            return XDP_PASS;
        }

        key.addr = ipv6_hdr->nexthdr;
        */
        break;
    }


    return XDP_PASS;
}

SEC("xdp/INTERFACE")
int trace_interface(struct xdp_md *ctx)
{
    return xdp_trace(ctx);
}

char LICENSE[] SEC("license") = "GPL";
