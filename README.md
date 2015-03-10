# SCLI_HTTP
Network bridge between RTI and Savant.

Can be run on smart or pro host.

Allows direct TCP or HTTP communication with sclibrige on port 12000.

The easiest way to test is in a browser with commands like:

```http://<address of host>:12000/readstate%20global.CurrentMonth```

```http://<address of host>:12000/statenames```

```http://<address of host>:12000/userzones```

```http://<address of host>:12000/writestate%20'userdefined.I%20wrote%20something'%20'to%20state%20center'```

```http://<address of host>:12000/readstate%20'userdefined.I%20wrote%20something'```

```http://<address of host>:12000/servicerequestcommand%20Rack-----PowerOff```

Or if we want to get really crazy.

***I don't recommend running this one on your host. Although it shouldn't hurt anything. It is just an example of a complicated trigger that can be created if you have the patience.
Essentially this creates a trigger called test trigger that runs once every second and executes a CLI script.
The CLI script reads a state from state center, base64 encodes it, and then writes the new value to another state.
This was biefly useful to 7.0 systems that wouldn't display coverart on some services.
```
http://<address of host>:12000/settrigger "artTrigger" "1" "String" "global" "CurrentSecond" "Not Equal" "" "0" "Boardroom" "ROSIE System Host" "" "1" "SVC_GEN_GENERIC" "RunCLIProgram" "COMMAND_STRING" '/usr/local/bin/sclibridge writestate "MediaBrowser.Media_server.CurrentArtworkPath" $(echo -n `/usr/local/bin/sclibridge readstate "MediaBrowser.Media_server.CurrentArtworkURL"` | base64 -w 0)'
```
The trigger can be removed from the sysem using the following.

```http://<address of host>:12000/removetrigger "artTrigger"```

Below is the sclibridge command list as of 7.1.1

```
usage: sclibridge <command> <command arguments>
  readstate 
     <first state name> ... - List of up to 100 state names, space seperated. Returns state names, 1 per line.
  writestate 
     <first state name> <first state value> ... - List of up to 100 state name and value pairs.
  servicerequest 
      <zone> <source component> <source logical component> <service variant> <service type> <request> <first argument name> <first argument value> ...
  servicerequestcommand 
      <dash separated service request: (zone)-(source component)-(source logical component)-(service variant)-(service type)-(request)> <first argument name> <first argument value> ...
      Note: prior to 5.2.1er2 the order of service variant and service type was reversed.  Upgrades to 5.2.1er2 and later that user servicerequestcommand must swap the order of these parameters.
  userzones - returns a list of the users zones, 1 per line.
  statenames - query names of states. NOTE: running this command can impact system performance.  It should be run as infrequently as possible
      <filter> - regular expression to filter returned states (optional)
  settrigger 
      <triggername> <transitionCount> <Match Entry Type> <Match Entry State Scope> <Match Entry State Name> <Match Logic> <Match Data> <prematchCount> <Match Entry Type> <Match Entry State Scope> <Match Entry State Name> <Match Logic> <Match Data> <serviceZone> <serviceSourceComponentName> <serviceLogicalName> <serviceVariant ID> <serviceType> <serviceReq> <serviceReq first argument name> <serviceReqfirst argument value> ...
               ********************************************************* 
               * If transitionCount is equl to 0, then the next five   * 
               * entries are not included, the next piece of data      * 
               * would be prematchcount, conversely if the count is    * 
               * greater then 1, then those five are repeated that     * 
               * many times.  If you are adding a Logical Operator of  * 
               * "OR" set the "Match Entry Type" to "State" and the    * 
               * "Match Entry State Scope" to "OR"                     * 
               *                                                       * 
               * Match Entry Types Supported                           * 
               *    Logic - OR is the only supported value             * 
               *    State - When you want to match another state       * 
               *    Bool - TRUE, true, FALSE, false                    * 
               *    String - Everything Else                           * 
               *                                                       * 
               * Example: (increment a state when sec = 0,20,40)       * 
               * /Users/RPM/Applications/RacePointMedia/sclibridge     * 
               * "testTrigger" "5" "String" "global" "CurrentSecond"   * 
               * "Equal" "0" "Logic" "OR" "String" "global" "CurrentSecond" "Equal" "20"* 
               * "Logic" "OR" "String" "global" "CurrentSecond" "Equal" "40" "0"        * 
               * "Shelbys Room" "Savant System" "" "1"                 * 
               *  "SVC_GEN_GENERIC" "RunCLIProgram" "COMMAND_STRING"   * 
               * "perl /Users/RPM/Documents/TestScripts/incStateVal.pl"* 
               ********************************************************* 
  removetrigger 
      <triggername> 


```
