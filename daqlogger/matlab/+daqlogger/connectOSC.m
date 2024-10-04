function connectOSC(obj)
    obj.OSCSender = osc_new_address(obj.osc_ipadress, obj.osc_port);
end