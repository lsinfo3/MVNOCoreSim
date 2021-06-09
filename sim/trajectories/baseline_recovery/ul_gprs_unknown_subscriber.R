trj_ul_gprs_unknown_hlr_hit <- trajectory() %>% 
  set_attribute("hlr_hit", 1) %>%
  join(trj_hlr_hit) %>% 
  join(trj_cmap_out)

trj_ul_gprs_unknown_hlr_miss <- trajectory() %>% 
  set_attribute("hlr_miss", 1) %>%
  join(trj_hlr_miss) %>% 
  timeout(function() update_cache_hlr(get_attribute(env, "device"), simmer::now(env))) %>% 
  #send(function() { paste0(get_attribute(env, "device"), "_cached_hlr")}) %>%
  join(trj_spc_hit) %>% # ul spc miss does not occur due to system design
  join(trj_cmap_out)

trj_ul_gprs_unknown <- trajectory() %>% 
  set_global("ulCurrent", 1, "+") %>% 
  join(trj_set_attributes) %>% 
  join(trj_cmap_in) %>% 
  branch(function() is_cached_hlr(get_attribute(env, "device"), simmer::now(env)),
         trj_ul_gprs_unknown_hlr_hit,
         trj_ul_gprs_unknown_hlr_miss,
         continue = c(T, T)) %>% 
  send(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_ul_gprs_success")) %>% 
  set_global("ulCurrent", -1, "+")

