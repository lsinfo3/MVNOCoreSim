# Set attributes
trj_set_attributes <- trajectory() %>%
  set_attribute("device", function() { i <- dev[1]; dev <<- tail(dev, -1); return(i) }) %>% 
  set_attribute("retry", function() { i <- ret[1]; ret <<- tail(ret, -1); return(i) })