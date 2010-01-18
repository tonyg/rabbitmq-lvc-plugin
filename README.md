# Last value caching exchange

This is a pretty simple implementation of a last value cache using
RabbitMQ's pluggable exchange types feature.  (At the minute this
feature is experimental, but it may end up in releases after 1.7.1.)

The last value cache is intended to solve problems like the following:
say I am using messaging to send notifications of some changing values
to clients; now, when a new client connects, it won't know the value
until it changes.

The last value exchange acts like a direct exchange (binding keys are
compared for equality with routing keys); but, it also keeps track of
the last value that was published with each routing key, and when a
queue is bound, it automatically enqueues the last value for the
binding key.

# How to use it

Set up rabbitmq-public-umbrella, as per the instructions
at http://www.rabbitmq.com/plugin-development.html, and update
rabbitmq-server to the "exchange types" branch:

    $ hg clone http://hg.rabbitmq.com/rabbitmq-public-umbrella
    $ cd rabbitmq-public-umbrella ; make checkout ; make
    $ (cd rabbitmq-server ; hg up -C bug22169 ; make -j)
    $ (cd ../rabbitmq-erlang-client ; make clean && make)

Then get the LVC plugin and symlink it into plugins:

    $ git clone git://github.com/squaremo/rabbitmq-lvc-plugin.git
    $ (cd rabbitmq-lvc-plugin ; make)
    $ mkdir -p rabbitmq-server/plugins
    $ cd rabbitmq-server/plugins
    $ ln -s ../../rabbitmq-lvc-plugin ./

and finally, run the server:
    $ cd ..
    $ make run

In the startup banner you should see a line something like

    starting rabbit_exchange_type_lvc                 ...done

TODO py-amqp example.

# Limitations

## "Recent value cache"

AMQP is inherently racey.  It is quite possible to see different
last-values but the same subsequent message stream, from different
clients.

This won't matter if you simply want to have a value to show until you
get an update.  If it does matter, consider e.g. using sequence IDs so you
can notice out-of-order messages.

There's also a race in the pluggable exchanges hook, so that clients
can "see" the binding before the hook has been run; for the LVC, this
means that there's a possiblity that messages will get queued before
the last value.  For this reason, I'm thinking of tagging the last
value messages so that clients can fast-forward to it, or ignore it,
if necessary.

## Values v. deltas

One question that springs to mind when considering last value caches
is "what if I'm sending deltas rather than the whole value?".  Thre
LVC exchange doesn't address this use case, but you could do it by
using two exchanges and posting full values to the LVC (from the
originating process -- presumably you'd be using deltas to save on
downstream bandwidth).

## Direct exchanges only

The semantics of another kind of value-caching exchange (other than
fanout) aren't obvious.  To choose one option though, say a
newly-bound queue was to be given all values that match its binding
key -- this would require every kind of exchange to supply a reverse
routing match procedure.