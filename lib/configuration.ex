# Rishabh Jain(rj2315) & Vinamra Agrawal(va1215)
# distributed algorithms, n.dulay, 2 feb 18
# multi-paxos, configuration parameters v1

defmodule Configuration do

def version 1 do	# configuration 1
  %{
  debug_level:  0, 	# debug level
  docker_delay: 5_000,	# time (ms) to wait for containers to start up
  window_size: 100,  # window size for slots in replica
  max_requests: 500,   	# max requests each client will make
  client_sleep: 5,	# time (ms) to sleep before sending new request
  client_stop:  10_000,	# time (ms) to stop sending further requests
  n_accounts:   100,	# number of active bank accounts
  max_amount:   1000,	# max amount moved between accounts

  print_after:  1_000,	# print transaction log summary every print_after msecs

  leader_sleep: false,  # boolean control for 'random wait' livelock prevention algorithm

  monitor_livelocks: false,  # boolean control for another 'random wait' livelock prevention algorithm
  check_livelock_interval: 50,

  livelock_prevention: true,  # boolean control for 'leader wait' livelock prevention algorithm

  rand_sleep_max: 100,  # max time to sleep when avoiding livelocks by random sleeps (in milliseconds)

  leader_resp_wait_time: 10  # time leader waits for a leader_resp response (in milliseconds)
  }
end

def version 2 do	# same as version 1 with higher debug level
 config = version 1
 Map.put config, :debug_level, 1
end

end # module -----------------------
