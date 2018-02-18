# Rishabh Jain(rj2315) & Vinamra Agrawal(va1215)
# distributed algorithms, n.dulay 2 feb 18
# coursework 2, paxos made moderately complex
defmodule Scout do
def start leader, p, acceptors do
  for a <- acceptors do
    send a, {:p1a, self(), p}
  end
  next acceptors, length(acceptors)/2, [], leader, p
end

defp next wait_for, min_acceptors, pvalues, leader, p do
  receive do
    {:p1b, a, acc_p, acc_accepted} ->
      if p == acc_p do
        pvalues = pvalues ++ acc_accepted
        wait_for = List.delete(wait_for, a)
        if length(wait_for) < min_acceptors do
          send leader, {:adopted, p, pvalues}
          Process.exit(self(), :kill)
        end
        next wait_for, min_acceptors, pvalues, leader, p
      else
        send leader, {:preempted, acc_p}
        Process.exit(self(), :kill)
      end
  end
end
end
