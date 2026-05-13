# symbol_readableuri

NEMTUS hackathon 2026 app.

You can use this app to create and send readable URIs.

It's made in this format.

```
symbol:$Address@$network/transfer?
id[0]=$MoId[0]&amount[0]=$amount[0]&div[0]=$divisibility[0]
&id[1]=$MoId[1]&amount[1]=$amount[1]&div[1]=$divisibility[1]...
```

The structure of the `transfer` to be reconstructed for signing is as follows.

```
{Network: test,
 Transaction: 
    [{
        Action: transfer,
        Network: $network,
        Address: $Address,
        Mosaics: [{
            Id: $MoId[0],
            Amount: $amount[0],
            Id: $MoId[1],
            Amount: $amount[1]
        }],
        Message: $messaga
    }, {
        Action: transfer,
        Network: test,
...
```

Everyone, please use it too!

[Slide Link](https://github.com/ChocoTanaka/symbol_readableuri/blob/master/Experiment%20to%20Simplify%20Symbol%20Tx%20Using%20Readable%20URIs.pdf)
