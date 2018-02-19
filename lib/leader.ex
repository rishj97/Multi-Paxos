# Rishabh Jain(rj2315) & Vinamra Agrawal(va1215)
# distributed algorithms, n.dulay 2 feb 18
# coursework 2, paxos made moderately complex

defmodule Leader do
def start config do
  propose_num = {0, self()}
  receive do
    {:bind, acceptors, replicas} ->
      spawn Scout, :start, [self(), propose_num, acceptors]
      next Map.new, false, acceptors, replicas, {0, self()}, config
  end
end

def next proposals, active, acceptors, replicas, propose_num, config do
  receive do
    {:propose, s, c} ->
      if not Map.has_key?(proposals, s) do
        Map.put(proposals, s, c)
        if active do
          spawn Commander, :start, [self(), acceptors, replicas, {propose_num, s, c}]
        end
        next proposals, active, acceptors, replicas, propose_num, config
      end
    {:adopted, acc_p, pvals} ->
      max_pvals = p_max pvals
      proposals = Map.merge(proposals, Map.new(max_pvals))
      for  {s, c}  <-  proposals  do
        spawn Commander, :start, [self(), acceptors, replicas, {acc_p, s, c}]
      end
      active = true
      next proposals, active, acceptors, replicas, propose_num, config
    {:preempted, {r, l}} ->
      if p_greater {r, l}, propose_num do
        active = false
        propose_num = {r + 1, self()}
        spawn Scout, :start, [self(), propose_num, acceptors]
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

def p_greater {r1, l1}, {r2, l2} do
  if r1 != r2 do
    r1 > r2
  else
    l1 > l2
  end
end
end
