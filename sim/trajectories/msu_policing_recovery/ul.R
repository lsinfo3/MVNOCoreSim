trj_isd_ul <- trajectory() %>% 
  simmer::select("isd") %>% 
  seize_selected() %>% 
  timeout(function() isd.function()) %>% 
  release_selected()

trj_ul_hlr_hit <- trajectory() %>% 
  set_attribute("hlr_hit", 1) %>%
  join(trj_hlr_hit) %>% 
  join(trj_isd_ul) %>% 
  join(trj_spc_sms) %>% 
  join(trj_cmap_out)

trj_ul_hlr_miss <- trajectory() %>% 
  set_attribute("hlr_miss", 1) %>%
  join(trj_hlr_miss) %>% 
  timeout(function() update_cache_hlr(get_attribute(env, "device"), simmer::now(env))) %>% 
  #send(function() { paste0(get_attribute(env, "device"), "_cached_hlr")}) %>%
  join(trj_spc_hit) %>% # ul spc miss does not occur due to system design
  join(trj_isd_ul) %>% 
  join(trj_spc_sms) %>% 
  join(trj_cmap_out)

trj_ul <- trajectory() %>% 
  join(trj_set_attributes) %>% 
  leave(prob = function() { ifelse(get_global(env, "ul_current") >= config$policing$ul, 1, 0)},
        out = trajectory() %>% 
          set_attribute("rejected", 1) %>% 
          set_global("ul_rejected", 1, "+") %>% 
          send(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_ul_reject"))) %>%
  set_attribute("rejected", 0) %>% 
  set_global("ul_current", 1, "+") %>% 
  join(trj_cmap_in) %>% 
  branch(function() is_cached_hlr(get_attribute(env, "device"), simmer::now(env)),
         trj_ul_hlr_hit,
         trj_ul_hlr_miss,
         continue = c(T, T)) %>% 
  send(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_ul_success")) %>% 
  set_global("ul_current", -1, "+")
