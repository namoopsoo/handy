

#### packet capture filters

* Havent been able to get this one to work yet but this is as claimed here, https://semfionetworks.com/wp-content/uploads/2021/04/wireshark_802.11_filters_-_reference_sheet.pdf

```
wlan_mgt.ssid == “your_SSID”
```

* and this one hmm did not work for me 

```
wlan.addr == xx:xx:xx:xx:xx:xx
```

* as opposed this, 

```
eth.addr == xx:xx:xx:xx:xx:xx
```

which did work for me.

* Maybe I can't see the low level 802.11 control packets/frames somehow.
