// btle_json.c
// Dependency-free NDJSON emitter. See btle_json.h for schema.

#include "btle_json.h"

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int g_enabled = 0;

void btj_init(int enabled) {
    g_enabled = enabled ? 1 : 0;
}

int btj_enabled(void) {
    return g_enabled;
}

static double ts_to_double(const struct timeval *tv) {
    if (!tv) return 0.0;
    return (double)tv->tv_sec + (double)tv->tv_usec / 1.0e6;
}

// Write 6-byte MAC as "aa:bb:cc:dd:ee:ff".
static void write_mac(FILE *out, const uint8_t mac[6]) {
    fprintf(out, "\"%02x:%02x:%02x:%02x:%02x:%02x\"",
            mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

// Write byte array as lowercase hex string.
static void write_hex(FILE *out, const uint8_t *bytes, int n) {
    fputc('"', out);
    for (int i = 0; i < n; i++) {
        fprintf(out, "%02x", bytes[i]);
    }
    fputc('"', out);
}

// Escape an ASCII C string into a JSON string literal. Naive — sufficient for
// short status messages and known-safe board names.
static void write_json_string(FILE *out, const char *s) {
    fputc('"', out);
    for (const char *p = s; *p; ++p) {
        unsigned char c = (unsigned char)*p;
        switch (c) {
            case '"':  fputs("\\\"", out); break;
            case '\\': fputs("\\\\", out); break;
            case '\n': fputs("\\n", out);  break;
            case '\r': fputs("\\r", out);  break;
            case '\t': fputs("\\t", out);  break;
            default:
                if (c < 0x20) fprintf(out, "\\u%04x", c);
                else          fputc((char)c, out);
        }
    }
    fputc('"', out);
}

void btj_emit_pkt_adv(const struct timeval *ts,
                      int pkt_count,
                      int channel,
                      uint32_t access_addr,
                      int crc_ok,
                      int pdu_type,
                      const char *pdu_name,
                      int tx_add,
                      int rx_add,
                      int payload_len,
                      const uint8_t *adv_a,
                      const uint8_t *payload_bytes,
                      int rssi_dbm)
{
    if (!g_enabled) return;

    FILE *out = stdout;
    fprintf(out,
            "{\"v\":1,\"t\":\"pkt\",\"ts\":%.6f,\"pkt\":%d,\"ch\":%d,"
            "\"aa\":\"%08x\",\"crc_ok\":%s,\"kind\":\"adv\","
            "\"pdu_type\":%d,\"pdu_name\":",
            ts_to_double(ts), pkt_count, channel,
            access_addr, crc_ok ? "true" : "false",
            pdu_type);
    write_json_string(out, pdu_name ? pdu_name : "UNKNOWN");
    fprintf(out, ",\"tx_add\":%d,\"rx_add\":%d,\"plen\":%d,\"adv_a\":",
            tx_add, rx_add, payload_len);
    if (adv_a) write_mac(out, adv_a);
    else       fputs("null", out);
    fputs(",\"payload_hex\":", out);
    write_hex(out, payload_bytes, payload_len);
    if (rssi_dbm == INT_MIN) fputs(",\"rssi_est\":null", out);
    else                     fprintf(out, ",\"rssi_est\":%d", rssi_dbm);
    fputs("}\n", out);
    fflush(out);
}

void btj_emit_pkt_data(const struct timeval *ts,
                       int pkt_count,
                       int channel,
                       uint32_t access_addr,
                       int crc_ok,
                       int ll_pdu_type,
                       const char *ll_pdu_name,
                       int nesn,
                       int sn,
                       int md,
                       int payload_len,
                       const uint8_t *payload_bytes,
                       int rssi_dbm)
{
    if (!g_enabled) return;

    FILE *out = stdout;
    fprintf(out,
            "{\"v\":1,\"t\":\"pkt\",\"ts\":%.6f,\"pkt\":%d,\"ch\":%d,"
            "\"aa\":\"%08x\",\"crc_ok\":%s,\"kind\":\"data\","
            "\"ll_pdu_type\":%d,\"ll_pdu_name\":",
            ts_to_double(ts), pkt_count, channel,
            access_addr, crc_ok ? "true" : "false",
            ll_pdu_type);
    write_json_string(out, ll_pdu_name ? ll_pdu_name : "UNKNOWN");
    fprintf(out, ",\"nesn\":%d,\"sn\":%d,\"md\":%d,\"plen\":%d,\"payload_hex\":",
            nesn, sn, md, payload_len);
    write_hex(out, payload_bytes, payload_len);
    if (rssi_dbm == INT_MIN) fputs(",\"rssi_est\":null", out);
    else                     fprintf(out, ",\"rssi_est\":%d", rssi_dbm);
    fputs("}\n", out);
    fflush(out);
}

void btj_emit_hop(const struct timeval *ts,
                  const char *event,
                  int state_from,
                  int state_to,
                  int channel,
                  uint64_t freq_mhz,
                  uint32_t aa,
                  uint32_t crc_init,
                  int interval_us,
                  int hop_increment,
                  const uint8_t *chm)
{
    if (!g_enabled) return;

    FILE *out = stdout;
    fprintf(out, "{\"v\":1,\"t\":\"hop\",\"ts\":%.6f,\"event\":", ts_to_double(ts));
    write_json_string(out, event ? event : "unknown");
    fprintf(out,
            ",\"state_from\":%d,\"state_to\":%d,\"ch\":%d,\"freq_mhz\":%llu,"
            "\"aa\":\"%08x\",\"crc_init\":\"%06x\","
            "\"interval_us\":%d,\"hop\":%d,\"chm\":",
            state_from, state_to, channel,
            (unsigned long long)freq_mhz,
            aa, crc_init & 0xFFFFFFu,
            interval_us, hop_increment);
    if (chm) write_hex(out, chm, 5);
    else     fputs("null", out);
    fputs("}\n", out);
    fflush(out);
}

void btj_emit_status(const struct timeval *ts,
                     const char *event,
                     const char *board,
                     int channel,
                     uint64_t freq_hz,
                     int gain,
                     int lna,
                     int amp,
                     const uint8_t *filter_adva,
                     const char *msg)
{
    if (!g_enabled) return;

    FILE *out = stdout;
    fprintf(out, "{\"v\":1,\"t\":\"status\",\"ts\":%.6f,\"event\":",
            ts_to_double(ts));
    write_json_string(out, event ? event : "unknown");
    fputs(",\"board\":", out);
    write_json_string(out, board ? board : "");
    fprintf(out, ",\"ch\":%d,\"freq_hz\":%llu,\"gain\":%d,\"lna\":%d,\"amp\":%d,"
                 "\"filter_adva\":",
            channel, (unsigned long long)freq_hz, gain, lna, amp);
    if (filter_adva) write_mac(out, filter_adva);
    else             fputs("null", out);
    fputs(",\"msg\":", out);
    if (msg) write_json_string(out, msg);
    else     fputs("null", out);
    fputs("}\n", out);
    fflush(out);
}
