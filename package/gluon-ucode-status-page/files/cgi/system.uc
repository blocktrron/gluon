#!/usr/bin/ucode
import * as status_page from 'gluon.status-page';

status_page.query_ubus('gluon.statistics.network', 'get_statistics');
