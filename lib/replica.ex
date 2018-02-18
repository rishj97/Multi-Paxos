# Rishabh Jain(rj2315) & Vinamra Agrawal(va1215)
# distributed algorithms, n.dulay 2 feb 18
# coursework 2, paxos made moderately complex

defmodule Replica do
def start config, database, monitor do
  receive do
    {:bind, leaders} -> next config, database, monitor, 1, 1, MapSet.new, Map.new, Map.new, leaders
  end
end

defp next config, database, monitor, slot_in, slot_out, requests, proposals, decisions, leaders do
  receive do
    { :client_request, c } -> MapSet.put(requests, c)
    { :decision, s, c } ->
      commands = Map.get(decisions, s, [])
      Map.put(decisions, s, commands ++ [c])
      commands = Map.get(decisions, s, [])
      for c <- commands do
        if Map.has_key?(proposals, slot_out) do
          proposal = Map.get(proposals, slot_out)
          requests = if proposal != c do
            Enum.concat(requests, [proposal])
          else
            requests
          end
          Map.delete(proposals, slot_out)
        end
        perform c, slot_out, decisions, database
      end
      propose requests, proposals, decisions, slot_in, slot_out, leaders, 3
  end
  next config, database, monitor, slot_in, slot_out, requests, proposals, decisions, leaders
end

defp perform {client, cid, transaction} = cmd, slot_out, decisions, database do
  if perform_cmd slot_out, cmd, decisions do
    send database, { :execute, transaction }
    send client, { :reply, cid, 1 } # 1 signifies successful transaction
  end
end

defp perform_cmd slot_out, cmd, decisions do
  should_perform = True
  for {s, c} <- decisions do
    if s < slot_out && Enum.member?(c, cmd) do
      should_perform = False
    end
  end
  should_perform
end

defp propose requests, proposals, decisions, slot_in, slot_out, leaders, window do
  if slot_in < slot_out + window && not Enum.empty?(MapSet.to_list(requests)) do
    for c <- MapSet.to_list(requests) do
      decision = Map.get(decisions, slot_in, [])
      if Enum.empty?(decision) do
        requests = MapSet.delete(requests, c)
        proposals = Map.put(proposals, slot_in, c)
        for l <- leaders do
          send l, { :propose, slot_in, c }
        end
      end
    end
    propose requests, proposals, decisions, slot_in+1, slot_out, leaders, window
  end
end

end
