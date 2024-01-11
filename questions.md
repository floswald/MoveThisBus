Dear Florian and Marleen, 

## 1 What is in the code
I have proceed with calling via mode to obtain vehicle and lineid, but the sample size is very small (obs 14 ish ), and the sample changes as I request during different time.
```R
resp_c<- req_c %>%
  req_url_query(!!!param) %>%
  req_throttle(rate = 500 / 60) %>%
  req_retry(backoff = ~ 10) %>%
  req_perform()
```
 I am not so sure is this what we are looking for, but I do find an answer to the tasks. 
 You could find my R script line 1-105 as an attempt to answer the question. 

##2 An Attempt that is unsuccessful at my end
From line 101-124 in code ( I have reached the maximum requests for today so I will leave it as a question)

Other than having a small sample size: 
My other thought would be, since we need 3 APIs but I have only used mode, 
1.  Obtaining the buses (mode) that are moving at the request time, 
2. From mode, obtain a list of unique vehicle;
3. Run a loop of calls via the vehicle API,  merge the buses_c and buses_v by vehicle ID, and see wether the line changes

However, my loop calling for vehicle id is not successful,  and I guess this is because for some vehicles that are running  in unique list (via mode), at the time that I call in (vehicle API ) are no longer available and the loop breaks. 

```R
for (i in bus_id) {
  v_resp <- req_vehicle %>%
    req_url_path_append(i) %>%
    req_url_path_append("Arrivals") %>%
    req_url_query(app_key = TFL_KEY) %>%
    req_throttle(rate = 500 / 60) %>%
    req_retry(backoff = ~10, max_tries = 12) %>%
    req_perform()
}
```
I know in stata there is a command ==capture== where it allows me to skip if error happens, I wonder maybe there is something similar in R and I can modify the code if this is the right way of doing the task. 

Thank you so much for the exercise, API seems to be super cool! 