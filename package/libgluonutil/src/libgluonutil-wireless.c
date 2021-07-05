/* SPDX-License-Identifier:  BSD-2-Clause */

#include "libgluonutil.h"

#include <json-c/json.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <iwinfo.h>

struct json_object *gluonutil_get_stations(const char *ifname) {
	int len;
	char buf[IWINFO_BUFSIZE];
	struct json_object *stations;

	const struct iwinfo_ops *iw = iwinfo_backend(ifname);
	if (!iw)
		return NULL;

	stations = json_object_new_object();

	if (iw->assoclist(ifname, buf, &len) == -1)
		return stations;

	// This is just: for entry in assoclist(ifname)
	for (struct iwinfo_assoclist_entry *entry = (struct iwinfo_assoclist_entry *)buf;
			(char*)(entry+1) <= buf + len; entry++) {
		struct json_object *station = json_object_new_object();

		json_object_object_add(station, "signal", json_object_new_int(entry->signal));
		json_object_object_add(station, "noise", json_object_new_int(entry->noise));
		json_object_object_add(station, "inactive", json_object_new_int(entry->inactive));

		char macstr[18];

		snprintf(macstr, sizeof(macstr), "%02x:%02x:%02x:%02x:%02x:%02x",
		entry->mac[0], entry->mac[1], entry->mac[2],
		entry->mac[3], entry->mac[4], entry->mac[5]);

		json_object_object_add(stations, macstr, station);
	}

	return stations;
}
