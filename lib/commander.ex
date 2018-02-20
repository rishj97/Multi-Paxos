# Rishabh Jain(rj2315) & Vinamra Agrawal(va1215)
# distributed algorithms, n.dulay 2 feb 18
# coursework 2, paxos made moderately complex
defmodule Commander do
def start leader, acceptors, replicas, cmd do
  for a <- acceptors do
    send a, { :p2a, self(), cmd }
  end
  next acceptors, length(acceptors)/2, leader, cmd, replicas
end

defp next wait_for, min_acceptors, leader, cmd, replicas do
  {p, s, c} = cmd
  receive do
    { :p2b, a, acc_p } ->
      if p == acc_p do
        wait_for = List.delete(wait_for, a)
        if length(wait_for) < min_acceptors do
          for r <- replicas do
            send r, { :decision, s, c }
          end
          Process.exit(self(), :kill)
        end
        next wait_for, min_acceptors, leader, cmd, replicas
      else
        send leader, { :preempted, acc_p }
        Process.exit(self(), :kill)
      end
  end
end
end
