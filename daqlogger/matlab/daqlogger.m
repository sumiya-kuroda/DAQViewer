OSCSender = osc_new_address('127.0.0.1', 59729);
% See
% https://github.com/sumiya-kuroda/oscmex/tree/master/example
% for more examples and detailed explanation.

msg = struct( ...
        'path', '/achn1', ... # address
        'data', {{1}} ... # needs to be cell
        );

% send the message...  
err = osc_send(OSCSender, msg); % send the message
osc_free_address(OSCSender);

