/* SPDX-License-Identifier: BSD-2-Clause */

#include <ucode/module.h>

#include <arpa/inet.h>
#include <fcntl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#define GLUON_NEIGHBOUR_INFO_PORT 1001
#define GLUON_NEIGHBOUR_INFO_BUFSIZE 8192

static uc_resource_type_t *neighbour_info_type;

struct neighbour_info {
	int sock;
	struct sockaddr_in6 group;
	char *recvbuf;
	size_t recvbuf_len;
};

static void neighbour_info_free(void *ptr) {
	struct neighbour_info *info = ptr;

	if (!info)
		return;

	if (info->sock >= 0)
		close(info->sock);

	free(info->recvbuf);
	free(info);
}

/* peeks the pending datagram size, grows recvbuf if needed, then reads it */
static ssize_t neighbour_info_recv(struct neighbour_info *info) {
	ssize_t len;
	char *buf;

	len = recv(info->sock, info->recvbuf, 0, MSG_PEEK | MSG_TRUNC);
	if (len < 0)
		return len;

	if ((size_t)len > info->recvbuf_len) {
		buf = realloc(info->recvbuf, len);
		if (!buf)
			return -1;

		info->recvbuf = buf;
		info->recvbuf_len = len;
	}

	return recv(info->sock, info->recvbuf, info->recvbuf_len, 0);
}

static uc_value_t *uc_neighbour_info_create(uc_vm_t *vm, size_t nargs) {
	uc_value_t *ifname_uc = uc_fn_arg(0);
	uc_value_t *group_uc = uc_fn_arg(1);
	struct neighbour_info *info;
	struct ipv6_mreq mreq = {};
	const char *ifname;
	unsigned int ifindex;
	int sock;

	if (ucv_type(ifname_uc) != UC_STRING || ucv_type(group_uc) != UC_STRING)
		return NULL;

	ifname = ucv_string_get(ifname_uc);

	ifindex = if_nametoindex(ifname);
	if (!ifindex)
		return NULL;

	if (inet_pton(AF_INET6, ucv_string_get(group_uc), &mreq.ipv6mr_multiaddr) != 1)
		return NULL;

	mreq.ipv6mr_interface = ifindex;

	sock = socket(AF_INET6, SOCK_DGRAM, 0);
	if (sock < 0)
		return NULL;

	if (setsockopt(sock, SOL_SOCKET, SO_BINDTODEVICE, ifname, strlen(ifname) + 1) < 0)
		goto err;

	if (setsockopt(sock, IPPROTO_IPV6, IPV6_MULTICAST_IF, &ifindex, sizeof(ifindex)) < 0)
		goto err;

	if (setsockopt(sock, IPPROTO_IPV6, IPV6_JOIN_GROUP, &mreq, sizeof(mreq)) < 0)
		goto err;

	if (fcntl(sock, F_SETFL, O_NONBLOCK) < 0)
		goto err;

	info = calloc(1, sizeof(*info));
	if (!info)
		goto err;

	info->sock = sock;
	info->recvbuf = malloc(GLUON_NEIGHBOUR_INFO_BUFSIZE);
	if (!info->recvbuf) {
		free(info);
		goto err;
	}
	info->recvbuf_len = GLUON_NEIGHBOUR_INFO_BUFSIZE;

	info->group.sin6_family = AF_INET6;
	info->group.sin6_port = htons(GLUON_NEIGHBOUR_INFO_PORT);
	info->group.sin6_addr = mreq.ipv6mr_multiaddr;
	info->group.sin6_scope_id = ifindex;

	return uc_resource_new(neighbour_info_type, info);

err:
	close(sock);
	return NULL;
}

static uc_value_t *uc_neighbour_info_query(uc_vm_t *vm, size_t nargs) {
	uc_value_t *obj_uc = uc_fn_arg(0);
	uc_value_t *request_uc = uc_fn_arg(1);
	struct neighbour_info *info;
	const char *request;

	info = ucv_resource_data(obj_uc, "gluon.neighbour-info");
	if (!info || ucv_type(request_uc) != UC_STRING)
		return NULL;

	request = ucv_string_get(request_uc);

	return ucv_boolean_new(sendto(info->sock, request, strlen(request), 0,
		(struct sockaddr *)&info->group, sizeof(info->group)) >= 0);
}

static uc_value_t *uc_neighbour_info_read(uc_vm_t *vm, size_t nargs) {
	uc_value_t *obj_uc = uc_fn_arg(0);
	struct neighbour_info *info;
	uc_value_t *ret;
	ssize_t recvlen;

	info = ucv_resource_data(obj_uc, "gluon.neighbour-info");
	if (!info)
		return NULL;

	ret = ucv_array_new(vm);

	while ((recvlen = neighbour_info_recv(info)) >= 0)
		ucv_array_push(ret, ucv_string_new_length(info->recvbuf, recvlen));

	return ret;
}

static const uc_function_list_t global_fns[] = {
	{ "create", uc_neighbour_info_create },
	{ "query", uc_neighbour_info_query },
	{ "read", uc_neighbour_info_read },
};

void uc_module_init(uc_vm_t *vm, uc_value_t *scope) {
	neighbour_info_type = ucv_resource_type_add(vm, "gluon.neighbour-info",
		ucv_object_new(vm), neighbour_info_free);

	uc_function_list_register(scope, global_fns);
}
