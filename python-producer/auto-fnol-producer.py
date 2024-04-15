import os

from confluent_kafka import Producer
from confluent_kafka.serialization import StringSerializer, SerializationContext, MessageField
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer

def read_config():
  config = {}
  with open("client.properties") as fh:
    for line in fh:
      line = line.strip()
      if len(line) != 0 and line[0] != "#":
        parameter, value = line.strip().split('=', 1)
        config[parameter] = value.strip()
  return config


def produce(topic, config):
  
    schema = "AutoFnol.avsc"

    path = os.path.realpath(os.path.dirname(__file__))
    with open(f"{path}/{schema}") as f:
        schema_str = f.read()


    schema_registry_conf = {
       'url': '<SR-URL>', 
       'basic.auth.user.info': '<SR-KEY>:<SR-SECRET>'
    }
    schema_registry_client = SchemaRegistryClient(schema_registry_conf)

    avro_serializer = AvroSerializer(schema_registry_client,
                                     schema_str)

    string_serializer = StringSerializer('utf_8')


    producer = Producer(config)

    fnol = {
       "account_id": 12345, 
       "loss_type": "ACCIDENT", 
       "date_of_loss": 739350,
       "date_of_fnol": 739351,  
       "state_of_loss": "MA",
       "amount_of_loss": 1500,
       "police_report_uploaded": False,
       "pictures_needed": False,
       "pictures_uploaded": False,
       "other_parties": []
    }

    producer.produce(
       topic=topic,
       key='test_message',
       value=avro_serializer(fnol, SerializationContext(topic, MessageField.VALUE))
    )

    producer.flush()


def main():
  config = read_config()
  topic = "auto-fnol"

  produce(topic, config)


main()