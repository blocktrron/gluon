#!/usr/bin/ucode
import * as status_page from 'gluon.status-page';

status_page.query_ubus('gluon.neighbour', 'get_neighbours');
