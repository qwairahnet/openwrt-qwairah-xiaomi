#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <arpa/inet.h>

static void get_mac(const char *iface, unsigned char *mac) {
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0) { memset(mac, 0, 6); return; }
    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, iface, IFNAMSIZ - 1);
    if (ioctl(fd, SIOCGIFHWADDR, &ifr) == 0) memcpy(mac, ifr.ifr_hwaddr.sa_data, 6);
    else memset(mac, 0, 6);
    close(fd);
}

static int add_tlv(unsigned char *buf, int offset, uint16_t type, const void *val, uint16_t len) {
    buf[offset++] = (type >> 8) & 0xFF;
    buf[offset++] = type & 0xFF;
    buf[offset++] = (len >> 8) & 0xFF;
    buf[offset++] = len & 0xFF;
    memcpy(buf + offset, val, len);
    return offset + len;
}

int main(void) {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) return 1;
    int bc = 1;
    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &bc, sizeof(bc));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(5678);
    addr.sin_addr.s_addr = inet_addr("255.255.255.255");

    uint16_t seq = 1;
    while (1) {
        unsigned char pkt[512], mac[6];
        char hostname[64] = "QWAIRAH-Xiaomi";
        char plat[64] = "Xiaomi MiWiFi Mini";

        FILE *fp = popen("uci -q get system.@system[0].hostname", "r");
        if (fp) {
            if (fgets(hostname, sizeof(hostname), fp)) hostname[strcspn(hostname, "\r\n")] = 0;
            pclose(fp);
        }
        FILE *mp = fopen("/tmp/sysinfo/model", "r");
        if (mp) {
            if (fgets(plat, sizeof(plat), mp)) plat[strcspn(plat, "\r\n")] = 0;
            fclose(mp);
        }
        if (plat[0] == '\0') strcpy(plat, "Xiaomi MiWiFi Mini");

        get_mac("br-lan", mac);
        int len = 0;
        pkt[len++] = 0; pkt[len++] = 0;
        pkt[len++] = (seq >> 8) & 0xFF; pkt[len++] = seq & 0xFF;
        seq++;

        const char *ver = "QWAIRAH OpenWrt 23.05";
        const char *iface = "br-lan";
        uint32_t uptime = htonl((uint32_t)time(NULL));

        len = add_tlv(pkt, len, 0x0001, mac, 6);
        len = add_tlv(pkt, len, 0x0005, hostname, (uint16_t)strlen(hostname));
        len = add_tlv(pkt, len, 0x0007, ver, (uint16_t)strlen(ver));
        len = add_tlv(pkt, len, 0x0008, plat, (uint16_t)strlen(plat));
        len = add_tlv(pkt, len, 0x000a, &uptime, 4);
        len = add_tlv(pkt, len, 0x0010, iface, (uint16_t)strlen(iface));

        sendto(sock, pkt, len, 0, (struct sockaddr *)&addr, sizeof(addr));
        sleep(15);
    }
    close(sock);
    return 0;
}
