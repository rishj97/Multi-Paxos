# Rishabh Jain(rj2315) & Vinamra Agrawal(va1215)
# distributed algorithms, n.dulay 2 feb 18
# coursework 2, paxos made moderately complex

defmodule Leader do
def start config do
  propose_num = {0, config.server_num}
  receive do
    { :bind, acceptors, replicas, leaders } ->
      spawn Scout, :start, [self(), propose_num, acceptors]
      next Map.new, false, acceptors, replicas, propose_num, config, false, leaders
  end
end

def next proposals, active, acceptors, replicas, propose_num, config, sleep_random, leaders do
  receive do
    { :sleep_random } ->
      next proposals, active, acceptors, replicas, propose_num, config, true, leaders
    { :propose, s, c } ->
      proposals = if not Map.has_key?(proposals, s) do
        if active do
          spawn Commander, :start, [self(), acceptors, replicas, {propose_num, s, c}]
        end
        Map.put(proposals, s, c)
      else
        proposals
      end
      next proposals, active, acceptors, replicas, propose_num, config, sleep_random, leaders
    { :adopted, acc_p, pvals } ->
      proposals = Map.merge(proposals, Map.new(p_max pvals))
      for {s, c} <- proposals do
        spawn Commander, :start, [self(), acceptors, replicas, {acc_p, s, c}]
      end
      next proposals, true, acceptors, replicas, propose_num, config, sleep_random, leaders
    { :preempted, {r, l} } ->
      sleep_random = if config.leader_sleep or sleep_random do
        Process.sleep DAC.random config.rand_sleep_max # Sleep randomly to avoid livelocks
        false
      end
      if {r, l} > propose_num do
        # If {r, l} is bigger than our current proposal number, we check with the
        # leading proposal number leader if it is active before increasing our proposal number
        # to avoid livelocks.
        for leader <- leaders do
          send leader, { :waiting, self(), l }
        end
        # Wait for the other leader's response
        receive do
          { :leader_resp } ->
            # Incase the leading leader responds, we dont change our proposal number.
            send self(), { :preempted, {r, l} }
            next proposals, active, acceptors, replicas, propose_num, config, sleep_random, leaders
        after config.leader_resp_wait_time ->
          # Incase of no response, we go about normally increasing our proposal number and spawning
          # our scout to start proposing.
          propose_num = {r + 1, config.server_num}
          spawn Scout, :start, [self(), propose_num, acceptors]
          next proposals, false, acceptors, replicas, propose_num, config, sleep_random, leaders
        end
      else
        next proposals, active, acceptors, replicas, propose_num, config, sleep_random, leaders
      end
    { :waiting, waiting_leader, waiting_on } ->
      if active and waiting_on == config.server_num do
        # If the leader is the one the waiting leader is waiting on and is active, we send a
        # response to the waiting leader, to tell it to wait.
        send waiting_leader, { :leader_resp }
      end
      next proposals, active, acceptors, replicas, propose_num, config, sleep_random, leaders
  end
end

def p_max pvals do
  if length(pvals) > 0 do
    sorted_pvals = Enum.sort(pvals, fn({p1, _, _}, {p2, _, _}) -> p1 >= p2 end)
    max_p = Enum.at(sorted_pvals, 0)
    max_pvals = Enum.filter(sorted_pvals, fn({p, _, _}) -> p == max_p end)
    for {_, s, c} <- max_pvals do
      {s, c}
    end
  else
    []
  end
end
end
