# Rishabh Jain(rj2315) & Vinamra Agrawal(va1215)
# distributed algorithms, n.dulay 2 feb 18
# coursework 2, paxos made moderately complex

defmodule Leader do
def start config do
  propose_num = {0, config.server_num}
  receive do
    { :bind, acceptors, replicas } ->
      spawn Scout, :start, [self(), propose_num, acceptors]
      next Map.new, false, acceptors, replicas, propose_num, config
  end
end

def next proposals, active, acceptors, replicas, propose_num, config do
  receive do
    { :propose, s, c } ->
      proposals = if not Map.has_key?(proposals, s) do
        if active do
          spawn Commander, :start, [self(), acceptors, replicas, {propose_num, s, c}]
        end
        Map.put(proposals, s, c)
      else
        proposals
      end
      next proposals, active, acceptors, replicas, propose_num, config
    { :adopted, acc_p, pvals } ->
      proposals = Map.merge(proposals, Map.new(p_max pvals))
      for {s, c} <- proposals do
        spawn Commander, :start, [self(), acceptors, replicas, {acc_p, s, c}]
      end
      next proposals, true, acceptors, replicas, propose_num, config
    { :preempted, {r, l} } ->
      Process.sleep DAC.random(100) # Sleep randomly to avoid livelocks
      if {r, l} > propose_num do
        propose_num = {r + 1, config.server_num}
        spawn Scout, :start, [self(), propose_num, acceptors]
        next proposals, false, acceptors, replicas, propose_num, config
      else
        next proposals, active, acceptors, replicas, propose_num, config
      end
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
