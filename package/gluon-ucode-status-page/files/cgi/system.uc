#!/usr/bin/ucode
import * as status_page from 'gluon.status-page';

status_page.query_ubus('gluon.statistics.system', 'get_statistics');
