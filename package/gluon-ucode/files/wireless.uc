import * as nl80211 from 'nl80211';
 
// Send a nl80211 request
 
export function get_phys() {
    return nl80211.request(nl80211.const.NL80211_CMD_GET_WIPHY, nl80211.const.NLM_F_DUMP, {});
}

export function get_survey(ifindex) {
    return nl80211.request(nl80211.const.NL80211_CMD_GET_SURVEY, nl80211.const.NLM_F_DUMP, { dev: ifindex });
}
