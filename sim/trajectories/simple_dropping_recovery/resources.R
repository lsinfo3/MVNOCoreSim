# Processing at backend components
trj_cmap_in <- trajectory() %>% 
  simmer::select("cmap") %>% 
  seize_selected(reject = trajectory() %>% set_attribute("cmap_in_reject", 1), continue = F) %>% 
  timeout(function() cmap.in.function()) %>% 
  release_selected()

trj_cmap_out_sai <- trajectory() %>% 
  simmer::select("cmap") %>% 
  seize_selected(reject = trajectory() %>% # Special case when cmap_out drops a dialog, as the AUC would never be released otherwise
                   set_attribute("cmap_out_reject", 1) %>%
                   timeout(function() auc.upseq.function()) %>% 
                   release("auc"), continue = F) %>% 
  timeout(function() cmap.out.function()) %>% 
  release_selected()

trj_cmap_out <- trajectory() %>% 
  simmer::select("cmap") %>% 
  seize_selected(reject = trajectory() %>% set_attribute("cmap_out_reject", 1), continue = F) %>% 
  timeout(function() cmap.out.function()) %>% 
  release_selected()

trj_hlr_hit <- trajectory() %>% 
  simmer::select("hlr") %>% 
  seize_selected(reject = trajectory() %>% set_attribute("hlr_reject", 1), continue = F) %>% 
  timeout(function() hlr.hit.function()) %>% 
  release_selected()

trj_hlr_miss <- trajectory() %>% 
  simmer::select("hlr") %>% 
  seize_selected(reject = trajectory() %>% set_attribute("hlr_reject", 1), continue = F) %>% 
  timeout(function() hlr.miss.function()) %>% 
  release_selected()

trj_auc_genkeys <- trajectory() %>% 
  seize("auc", reject = trajectory() %>% set_attribute("auc_reject", 1), continue = F) %>% 
  timeout(function() auc.genkeys.function())

trj_auc_upseq <- trajectory() %>% 
  timeout(function() auc.upseq.function()) %>% 
  release("auc")

## trj_isd is defined for each specific dialog type due to different number of ISDs

trj_spc_sms <- trajectory() %>% 
  simmer::select("spc") %>% 
  seize_selected(reject = trajectory() %>% set_attribute("spc_reject", 1), continue = F) %>% 
  timeout(function() spc.sms.function()) %>% 
  release_selected()

trj_spc_dbquery <- trajectory() %>% 
  simmer::select("spc") %>% 
  seize_selected(reject = trajectory() %>% set_attribute("spc_reject", 1), continue = F) %>% 
  timeout(function() spc.dbquery.function()) %>% 
  release_selected()

trj_spc_hit <- trajectory() %>% 
  simmer::select("spc") %>% 
  seize_selected(reject = trajectory() %>% set_attribute("spc_reject", 1), continue = F) %>% 
  timeout(function() spc.hit.function()) %>% 
  release_selected()

trj_spc_miss <- trajectory() %>% 
  simmer::select("spc") %>% 
  seize_selected(reject = trajectory() %>% set_attribute("spc_reject", 1), continue = F) %>% 
  timeout(function() spc.miss.function()) %>% 
  release_selected()