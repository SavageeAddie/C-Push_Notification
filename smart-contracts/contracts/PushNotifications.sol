// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract PushNotifications {
    event NotifyOneInChannel(
        address recipient,
        uint256 channel,
        string title,
        string action,
        string body,
        string imageHash,
        bool privateNotification
    );

    event NotifyAllInChannel(
        uint256 channel,
        string title,
        string action,
        string body,
        string imageHash
    );

    struct Channel {
        string name;
        string description;
        string iconHash;
        string badgeHash;
        address admin;
        address[] subscribers;
    }

    // channel index => pushing address => permission boolean
    mapping(uint256 => mapping(address => bool)) public pushAccess;
    Channel[] public channels; // dynamic array containing info on various channels
    // user address => channel index => subscription boolean
    mapping (address => mapping(uint256 => bool)) public subscriptions;
    mapping (address => string) public publicKeys; // used for sending notifications privately to one person

    function subscribe(uint256 _channel) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist.");
        require(!subscriptions[msg.sender][_channel], "Already subscribed.");
        subscriptions[msg.sender][_channel] = true;
        channels[_channel].subscribers.push(msg.sender);
        return true;
    }

    function unsubscribe(uint256 _channel) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist.");
        require(subscriptions[msg.sender][_channel], "Not subscribed.");
        subscriptions[msg.sender][_channel] = false;
        Channel storage channel = channels[_channel];
        uint256 length = channel.subscribers.length;
        for (uint256 i = 0; i < length; i++) {
            if (channel.subscribers[i] == msg.sender) {
                // Move the last element into the place to delete
                channel.subscribers[i] = channel.subscribers[length - 1];
                channel.subscribers.pop(); // Remove the last element
                break;
            }
        }
        return true;
    }

    function createChannel(
        string memory _name,
        string memory _description,
        string memory _iconHash,
        string memory _badgeHash
    ) public returns (uint256) {
        channels.push(Channel({
            name: _name,
            description: _description,
            iconHash: _iconHash,
            badgeHash: _badgeHash,
            admin: msg.sender,
            subscribers: new address 
        }));
        return channels.length; // return the new length of channels array
    }

    function editChannel(
        uint256 _channel,
        string memory _name,
        string memory _description,
        string memory _iconHash,
        string memory _badgeHash
    ) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist.");
        require(msg.sender == channels[_channel].admin, "Only admin can edit.");
        Channel storage channel = channels[_channel];
        channel.name = _name;
        channel.description = _description;
        channel.iconHash = _iconHash;
        channel.badgeHash = _badgeHash;
        return true;
    }

    function setPublicKey(string memory _publicKey) public returns (bool) {
        publicKeys[msg.sender] = _publicKey;
        return true;
    }

    function setPushAccess(uint256 _channel, address _address, bool _access) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist.");
        require(msg.sender == channels[_channel].admin, "Only admin can set push access.");
        pushAccess[_channel][_address] = _access;
        return true;
    }

    function notifyOneInChannel(
        address _recipient,
        uint256 _channel,
        string memory _title,
        string memory _action,
        string memory _body,
        string memory _imageHash,
        bool _privateNotification
    ) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist.");
        Channel memory channel = channels[_channel];
        if (_privateNotification) {
            require(channel.admin == msg.sender, "Private notification can only be
            require(channel.admin == msg.sender, "Private notification can only be sent by the admin.");
        } else {
            require(channel.admin == msg.sender || pushAccess[_channel][msg.sender], "Public notifications can only be sent by the admin or authorized addresses.");
        }
        require(subscriptions[_recipient][_channel], "Recipient must be subscribed to the channel.");

        emit NotifyOneInChannel(_recipient, _channel, _title, _action, _body, _imageHash, _privateNotification);
        return true;
    }

    function notifyAllInChannel(
        uint256 _channel,
        string memory _title,
        string memory _action,
        string memory _body,
        string memory _imageHash
    ) public returns (bool) {
        require(_channel < channels.length, "Channel does not exist.");
        Channel storage channel = channels[_channel];
        require(channel.admin == msg.sender || pushAccess[_channel][msg.sender], "Only admin or authorized addresses can send notifications.");

        emit NotifyAllInChannel(_channel, _title, _action, _body, _imageHash);
        return true;
    }

    function subscribersCountInChannel(uint256 _channel) public view returns (uint256) {
        require(_channel < channels.length, "Channel does not exist.");
        return channels[_channel].subscribers.length;
    }

    function subscribersInChannel(uint256 _channel) public view returns (address[] memory) {
        require(_channel < channels.length, "Channel does not exist.");
        return channels[_channel].subscribers;
    }

    function allChannels() public view returns (Channel[] memory) {
        return channels;
    }
}
