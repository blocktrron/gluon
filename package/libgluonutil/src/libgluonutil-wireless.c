/* SPDX-License-Identifier:  BSD-2-Clause */

#include "libgluonutil.h"

#include <json-c/json.h>

#include <inttypes.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <net/if.h>
#include <linux/netlink.h>
#include <linux/nl80211.h>
#include <netlink/handlers.h>
#include <netlink/genl/genl.h>
#include <netlink/genl/ctrl.h>

struct nl_station_data {
	int ifx;
	int noise;
	struct json_object *stations;
};

static void gluonutil_nl_msg_parse(struct nl_msg *msg, struct nlattr **tb)
{
	struct genlmsghdr *gnlh = nlmsg_data(nlmsg_hdr(msg));

	nla_parse(tb, NL80211_ATTR_MAX, genlmsg_attrdata(gnlh, 0),
	          genlmsg_attrlen(gnlh, 0), NULL);
}

static int get_noise_handler(struct nl_msg *msg, void *arg)
{
	struct nl_station_data *data = (struct nl_station_data *) arg;
	struct nlattr *tb[NL80211_ATTR_MAX + 1];
	struct nlattr *si[NL80211_SURVEY_INFO_MAX + 1];

	static struct nla_policy sp[NL80211_SURVEY_INFO_MAX + 1] = {
		[NL80211_SURVEY_INFO_NOISE]     = { .type = NLA_U8  },
	};

	gluonutil_nl_msg_parse(msg, tb);

	if (!tb[NL80211_ATTR_SURVEY_INFO])
		return NL_SKIP;

	if (nla_parse_nested(si, NL80211_SURVEY_INFO_MAX,
	                     tb[NL80211_ATTR_SURVEY_INFO], sp))
		return NL_SKIP;

	if (!si[NL80211_SURVEY_INFO_NOISE])
		return NL_SKIP;

	if (!si[NL80211_SURVEY_INFO_IN_USE])
		return NL_SKIP;

	data->noise = (int)(int8_t)nla_get_u8(si[NL80211_SURVEY_INFO_NOISE]);

	return NL_SKIP;
}

static json_object *get_station_handler_parse_rate(struct nlattr *bitrate_attr) {
	struct nlattr *rate_info[NL80211_RATE_INFO_MAX + 1];
	static struct nla_policy rate_policy[NL80211_RATE_INFO_MAX + 1] = {
		[NL80211_RATE_INFO_BITRATE] = { .type = NLA_U16 },
		[NL80211_RATE_INFO_BITRATE32] = { .type = NLA_U32 },
		[NL80211_RATE_INFO_MCS] = { .type = NLA_U8 },
		[NL80211_RATE_INFO_40_MHZ_WIDTH] = { .type = NLA_FLAG },
		[NL80211_RATE_INFO_SHORT_GI] = { .type = NLA_FLAG },
	};

	struct json_object *rate_obj;

	if (nla_parse_nested(rate_info, NL80211_RATE_INFO_MAX, bitrate_attr, rate_policy))
		return NULL;

	rate_obj = json_object_new_object();
	json_object_object_add(rate_obj, "rate", json_object_new_int(nla_get_u32(rate_info[NL80211_RATE_INFO_BITRATE32]) * 10));

	return rate_obj;
}

static int get_station_handler(struct nl_msg *msg, void *arg) {
	struct nl_station_data *data = (struct nl_station_data *) arg;

	struct nlattr *tb[NL80211_ATTR_MAX + 1];

	struct nlattr *station_info[NL80211_STA_INFO_MAX + 1];
	static struct nla_policy stats_policy[NL80211_STA_INFO_MAX + 1] = {
		[NL80211_STA_INFO_INACTIVE_TIME] = { .type = NLA_U32 },
		[NL80211_STA_INFO_RX_BYTES] = { .type = NLA_U32 },
		[NL80211_STA_INFO_TX_BYTES] = { .type = NLA_U32 },
		[NL80211_STA_INFO_RX_PACKETS] = { .type = NLA_U32 },
		[NL80211_STA_INFO_TX_PACKETS] = { .type = NLA_U32 },
		[NL80211_STA_INFO_RX_BITRATE] = { .type = NLA_NESTED },
		[NL80211_STA_INFO_TX_BITRATE] = { .type = NLA_NESTED },
		[NL80211_STA_INFO_SIGNAL] = { .type = NLA_U8 },
	};

	uint8_t *nla_mac_ptr;
	char macbuf[18];

	struct json_object *station;

	gluonutil_nl_msg_parse(msg, tb);

	if (!tb[NL80211_ATTR_STA_INFO]) {
		return NL_SKIP;
	}

	if (nla_parse_nested(station_info, NL80211_STA_INFO_MAX,
			     tb[NL80211_ATTR_STA_INFO],
			     stats_policy)) {
		return NL_SKIP;
	}

	station = json_object_new_object();

	nla_mac_ptr = nla_data(tb[NL80211_ATTR_MAC]);
	sprintf(macbuf, "%02x:%02x:%02x:%02x:%02x:%02x",
		 nla_mac_ptr[0], nla_mac_ptr[1], nla_mac_ptr[2],
		 nla_mac_ptr[3], nla_mac_ptr[4], nla_mac_ptr[5]);

	json_object_object_add(station, "inactive", json_object_new_int(nla_get_u32(station_info[NL80211_STA_INFO_INACTIVE_TIME])));
	json_object_object_add(station, "signal", json_object_new_int((int8_t)nla_get_u8(station_info[NL80211_STA_INFO_SIGNAL])));
	json_object_object_add(station, "noise", json_object_new_int(data->noise));

	json_object_object_add(station, "rx_bytes", json_object_new_int(nla_get_u32(station_info[NL80211_STA_INFO_RX_BYTES])));
	json_object_object_add(station, "tx_bytes", json_object_new_int(nla_get_u32(station_info[NL80211_STA_INFO_TX_BYTES])));

	json_object_object_add(station, "rx_packets", json_object_new_int(nla_get_u32(station_info[NL80211_STA_INFO_RX_PACKETS])));
	json_object_object_add(station, "tx_packets", json_object_new_int(nla_get_u32(station_info[NL80211_STA_INFO_TX_PACKETS])));

	/* Rate information */
	json_object_object_add(station, "rx_rate", get_station_handler_parse_rate(station_info[NL80211_STA_INFO_RX_BITRATE]));
	json_object_object_add(station, "tx_rate", get_station_handler_parse_rate(station_info[NL80211_STA_INFO_TX_BITRATE]));

	json_object_object_add(data->stations, macbuf, station);

	return NL_SKIP;
}

/* taken from respondd-module-airtime */
static bool nl_send_dump(nl_recvmsg_msg_cb_t cb, void *cb_arg, int cmd, uint32_t cmd_arg) {
	bool ok = false;
	int ret;
	int ctrl;
	struct nl_sock *sk = NULL;
	struct nl_msg *msg = NULL;


#define ERR(...) { fprintf(stderr, "libgluonutil-wireless: " __VA_ARGS__); goto out; }

	sk = nl_socket_alloc();
	if (!sk)
		ERR("nl_socket_alloc() failed\n");

	ret = genl_connect(sk);

	if (ret < 0)
		ERR("genl_connect() returned %d\n", ret);

	ctrl = genl_ctrl_resolve(sk, NL80211_GENL_NAME);
	if (ctrl < 0)
		ERR("genl_ctrl_resolve() returned %d\n", ctrl);

	ret = nl_socket_modify_cb(sk, NL_CB_VALID, NL_CB_CUSTOM, cb, cb_arg);
	if (ret != 0)
		ERR("nl_socket_modify_cb() returned %d\n", ret);

	msg = nlmsg_alloc();
	if (!msg)
		ERR("nlmsg_alloc() failed\n");

	if (!genlmsg_put(msg, 0, 0, ctrl, 0, NLM_F_DUMP, cmd, 0))
		ERR("genlmsg_put() failed while putting cmd %d\n", ret, cmd);

	if (cmd_arg != 0)
		NLA_PUT_U32(msg, NL80211_ATTR_IFINDEX, cmd_arg);

	ret = nl_send_auto_complete(sk, msg);
	if (ret < 0)
		ERR("nl_send_auto() returned %d while sending cmd %d with cmd_arg=%"PRIu32"\n", ret, cmd, cmd_arg);

	ret = nl_recvmsgs_default(sk);
	if (ret < 0)
		ERR("nl_recv_msgs_default() returned %d while receiving cmd %d with cmd_arg=%"PRIu32"\n", ret, cmd, cmd_arg);

#undef ERR

	ok = true;

nla_put_failure:
out:
	if (msg)
		nlmsg_free(msg);

	if (sk)
		nl_socket_free(sk);

	return ok;
}


struct json_object *gluonutil_get_stations(const char *ifname) {
	struct nl_station_data data = {};

	data.ifx = if_nametoindex(ifname);
	if (!data.ifx)
		return NULL;

	data.stations = json_object_new_object();

	nl_send_dump(get_noise_handler, &data, NL80211_CMD_GET_SURVEY, data.ifx);
	nl_send_dump(get_station_handler, &data, NL80211_CMD_GET_STATION, data.ifx);

	return data.stations;
}
