### The problem Celo Push Notification Service solves

 WEB3 is revolutionary in every manner, except for how it expects you to go and check again and again for simple things instead of delivering important notifications and alerts right to you like every app in WEB2 land does. This leads to bad UX and forces people to open these apps again and again just to check what's changed while they were away. CPNS is here to change that.

### Challenges I ran into
I ran into several challenges while building this project:

1. I had to learn how to ensure end to end notification of notification payloads. The decryption part was especially difficult because decryption is a resource intensive operation and thus not allowed in service workers. A couple of days after I encountered this issue, I came up with a clever solution for this by saving the encrypted payload in indexedDB and decrypting only on user interaction with the notification.

2. Another huge challenge was websockets, more specifically how unreliable they are on test nets. The websockets keep disconnecting and/or missing events which is not good. I made this issue less of a problem by writing a reconnection script which refreshes the connection to Celo Node every time it disconnects. It's far from perfect still but much better than how it was originally.