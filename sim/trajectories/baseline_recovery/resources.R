# Processing at backend components
trj_cmap_in <- trajectory() %>% 
  simmer::select("cmap") %>% 
  seize_selected() %>% 
  timeout(function() cmap.in.function()) %>% 
  release_selected()

trj_cmap_out <- trajectory() %>% 
  simmer::select("cmap") %>% 
  seize_selected() %>% 
  timeout(function() cmap.out.function()) %>% 
  release_selected()

trj_hlr_hit <- trajectory() %>% 
  simmer::select("hlr") %>% 
  seize_selected() %>% 
  timeout(function() hlr.hit.function()) %>% 
  release_selected()

trj_hlr_miss <- trajectory() %>% 
  simmer::select("hlr") %>% 
  seize_selected() %>% 
  timeout(function() hlr.miss.function()) %>% 
  release_selected()

trj_auc_genkeys <- trajectory() %>% 
  seize("auc") %>% 
  timeout(function() auc.genkeys.function())

trj_auc_upseq <- trajectory() %>% 
  timeout(function() auc.upseq.function()) %>% 
  release("auc")

## trj_isd is defined for each specific dialog type due to different number of ISDs

trj_spc_sms <- trajectory() %>% 
  simmer::select("spc") %>% 
  seize_selected() %>% 
  timeout(function() spc.sms.function()) %>% 
  release_selected()

trj_spc_dbquery <- trajectory() %>% 
  simmer::select("spc") %>% 
  seize_selected() %>% 
  timeout(function() spc.dbquery.function()) %>% 
  release_selected()

trj_spc_hit <- trajectory() %>% 
  simmer::select("spc") %>% 
  seize_selected() %>% 
  timeout(function() spc.hit.function()) %>% 
  release_selected()

trj_spc_miss <- trajectory() %>% 
  simmer::select("spc") %>% 
  seize_selected() %>% 
  timeout(function() spc.miss.function()) %>% 
  release_selected()