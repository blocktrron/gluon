/* SPDX-License-Identifier: GPL-2.0-only */

/*
 * Utility for performing remote command on Gluon nodes
 *
 * Copyright (c) David Bauer <mail@david-bauer.net>
 */

#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <ifaddrs.h>
#include <sys/types.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <net/ethernet.h>
#include <string.h>
#include <net/if.h>
#include <errno.h>
#include <sys/ioctl.h>

#include "gluon-remote-setup-mode.h"


char packet_base[] = {
	/* Destination - LLDP Multicast */
	REMOTE_SETUP_MODE_DST_MAC,
	/* Source */
	REMOTE_SETUP_MODE_SRC_MAC,
	/* Type */
	REMOTE_SETUP_MODE_ETHERTYPE,
};

char buf[REMOTE_CMD_BUF_SIZE] = {};


char *get_mac_address(const char *ifname) {
	static uint8_t addr[ETH_ALEN];
	struct ifaddrs *ifaddr, *ifa;
	struct sockaddr_ll *ethaddr;
	int ret;

	ret = getifaddrs(&ifaddr);
	if (ret < 0) {
		return NULL;
	}

	for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
		if (ifa->ifa_addr == NULL)
			continue;

		if (strcmp(ifname, ifa->ifa_name))
			continue;

		if (ifa->ifa_addr->sa_family == AF_PACKET && ifa->ifa_data != NULL) {
			ethaddr = (struct sockaddr_ll*)ifa->ifa_addr;
			memcpy(addr, ethaddr->sll_addr, ETH_ALEN);
		}
	}

	freeifaddrs(ifaddr);

	return addr;
}

int main(int argc, char *argv[])
{
	struct sockaddr_ll sll;
	char *ethaddr;
	int ifindex;
	int s_fd = 0;
	int ret = 0;

	if (argc < 3 || !strcmp("help", argv[1])) {
		fprintf(stderr, "Usage: %s <ifname> <command\n", argv[0]);
		ret = 1;
		goto out;
	}

	if (strlen(argv[2]) > REMOTE_CMD_MAX_CMD_STRLEN) {
		fprintf(stderr, "Command must be %d characters or less!\n", REMOTE_CMD_MAX_CMD_STRLEN);
		ret = 1;
		goto out;
	}

	ethaddr = get_mac_address(argv[1]);
	if (!ethaddr) {
		fprintf(stderr, "Could not get MAC address for interface %s!\n", argv[1]);
		ret = 1;
		goto out;
	}

	ifindex = if_nametoindex(argv[1]);
	if (!ifindex) {
		fprintf(stderr, "Coulld not get ifindex for interface \"%s\": %s\n", argv[1], strerror(errno));
		ret = 1;
		goto out;
	}

	memcpy(buf, packet_base, sizeof(packet_base));
	memcpy(&buf[sizeof(packet_base)], argv[2], strlen(argv[2]));
	memcpy(&buf[REMOTE_SETUP_MODE_SRC_MAC_OFFSET], ethaddr, ETH_ALEN);

	s_fd = socket(AF_PACKET,SOCK_RAW,htons(ETH_P_ALL));
	if (s_fd < 0) {
		fprintf(stderr, "Socket error: %s\n", strerror(errno));
		ret = 1;
		goto out;
	}

	memset(&sll, 0, sizeof(sll));
	sll.sll_family = AF_PACKET;
	sll.sll_ifindex = ifindex;

	printf("Sending command \"%s\" on interface %s\n", argv[2], argv[1]);
	while (1) {
		if (sendto(s_fd, buf, sizeof(buf), 0, (struct sockaddr *) &sll, sizeof(sll)) < 0) {
			fprintf(stderr, "Error sending packet: %s\n", strerror(errno));
			ret = 1;
			goto out;
		}

		usleep(250 * 1000);
	}

out:
	if (s_fd) {
		close(s_fd);
	}

	return ret;
}
