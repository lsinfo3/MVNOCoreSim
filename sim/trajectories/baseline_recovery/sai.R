trj_sai_hlr_hit <- trajectory() %>% 
  set_attribute("hlr_hit", 1) %>% 
  join(trj_hlr_hit) %>% 
  join(trj_auc_genkeys) %>% 
  join(trj_cmap_out) %>% 
  send(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_sai_success")) %>% 
  #log_(function() paste0("Send sai_success to ", get_attribute(env, "device"))) %>% 
  join(trj_auc_upseq)

trj_sai_spc_hit <- trajectory() %>% 
  set_attribute("spc_hit", 1) %>%
  join(trj_spc_hit) %>% 
  join(trj_auc_genkeys) %>% 
  join(trj_cmap_out) %>% 
  send(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_sai_success")) %>% 
  #log_(function() paste0("Send sai_success to ", get_attribute(env, "device"))) %>% 
  join(trj_auc_upseq)

trj_sai_spc_miss <- trajectory() %>% 
  set_attribute("spc_miss", 1) %>%
  join(trj_spc_miss) %>% 
  timeout(function() update_cache_spc(get_attribute(env, "device"), simmer::now(env))) %>% 
  #send(function() { paste0(get_attribute(env, "device"), "_cached_spc")}) %>% 
  join(trj_auc_genkeys) %>% 
  join(trj_cmap_out) %>% 
  send(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_sai_success")) %>% 
  #log_(function() paste0("Send sai_success to ", get_attribute(env, "device"))) %>% 
  join(trj_auc_upseq)

trj_sai_hlr_miss <- trajectory() %>% 
  set_attribute("hlr_miss", 1) %>%
  join(trj_hlr_miss) %>% 
  timeout(function() update_cache_hlr(get_attribute(env, "device"), simmer::now(env))) %>% 
  #send(function() { paste0(get_attribute(env, "device"), "_cached_hlr")}) %>% 
  branch(function() is_cached_spc(get_attribute(env, "device"), simmer::now(env)),
         trj_sai_spc_hit,
         trj_sai_spc_miss,
         continue = c(T, T))

trj_sai_vlr <- trajectory() %>% 
  set_global("sai_vlr_current", 1, "+") %>% 
  join(trj_set_attributes) %>% 
  join(trj_cmap_in) %>% 
  branch(function() is_cached_hlr(get_attribute(env, "device"), simmer::now(env)),
         trj_sai_hlr_hit,
         trj_sai_hlr_miss,
         continue = c(T, T)) %>% 
  set_global("sai_vlr_current", -1, "+")

trj_sai_sgsn <- trajectory() %>% 
  set_global("sai_sgsn_current", 1, "+") %>% 
  join(trj_set_attributes) %>% 
  join(trj_cmap_in) %>% 
  branch(function() is_cached_hlr(get_attribute(env, "device"), simmer::now(env)),
         trj_sai_hlr_hit,
         trj_sai_hlr_miss,
         continue = c(T, T)) %>% 
  set_global("sai_sgsn_current", -1, "+")

