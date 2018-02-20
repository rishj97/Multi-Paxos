# Rishabh Jain(rj2315) & Vinamra Agrawal(va1215)
# distributed algorithms, n.dulay 2 feb 18
# coursework 2, paxos made moderately complex

defmodule Replica do
def start config, database, monitor do
  receive do
    { :bind, leaders } -> next config, database, monitor, 1, 1, [], Map.new, Map.new, leaders
  end
end

defp next config, database, monitor, slot_in, slot_out, requests, proposals, decisions, leaders do
  receive do
    { :client_request, c } ->
      send monitor, { :client_request, config.server_num }
      next config, database, monitor, slot_in, slot_out, [c | requests], proposals, decisions, leaders
    { :decision, s, c } ->
      decisions = Map.put(decisions, s, c)
      {slot_in, slot_out, requests, proposals} = parse_decisions decisions, proposals, requests, slot_in, slot_out, database
      next config, database, monitor, slot_in, slot_out, requests, proposals, decisions, leaders
    after 0 ->
      {requests, proposals, slot_in} = propose requests, proposals, decisions, slot_in, slot_out, leaders, config.window_size
      next config, database, monitor, slot_in, slot_out, requests, proposals, decisions, leaders
  end
end

defp parse_decisions decisions, proposals, requests, slot_in, slot_out, database do
  if Map.has_key?(decisions, slot_out) do
    decisions_cmd = Map.get(decisions, slot_out)
    proposal = Map.get(proposals, slot_out)
    proposals = Map.delete(proposals, slot_out)
    requests = if proposal != decisions_cmd && proposal do
      [proposal | requests]
    else
      requests
    end
    slot_out = perform decisions_cmd, slot_out, decisions, database
    parse_decisions decisions, proposals, requests, slot_in, slot_out, database
  else
    {slot_in, slot_out, requests, proposals}
  end
end

defp perform cmd, slot_out, decisions, database do
  {client, cid, transaction} = cmd
  if perform_cmd slot_out, cmd, decisions do
    send database, { :execute, transaction }
    send client, { :reply, cid, 1 } # 1 signifies successful transaction
  end
  slot_out + 1
end

defp perform_cmd slot_out, cmd, decisions do
  bools = Enum.map(decisions, fn({s, c}) -> s < slot_out && c == cmd end)
  not Enum.member?(bools, true)
end

defp propose requests, proposals, decisions, slot_in, slot_out, leaders, window do
  if slot_in < (slot_out + window) && not Enum.empty?(requests) do
    {requests, proposals} = propose_requests requests, proposals, decisions, slot_in, leaders
    propose requests, proposals, decisions, slot_in + 1, slot_out, leaders, window
  else
    {requests, proposals, slot_in}
  end
end

defp propose_requests requests, proposals, decisions, slot_in, leaders do
  [c | left_requests] = requests
  if not Map.has_key?(decisions, slot_in) do
    proposals = Map.put(proposals, slot_in, c)
    for l <- leaders do
      send l, { :propose, slot_in, c }
    end
    {left_requests, proposals}
  else
    {requests, proposals}
  end
end

end
