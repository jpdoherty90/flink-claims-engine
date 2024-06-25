import os
import time
import random
import uuid

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
       'url': '', 
       'basic.auth.user.info': ':'
    }
    print("SETTING UP SCHEMA REGISTRY CLIENT")
    schema_registry_client = SchemaRegistryClient(schema_registry_conf)
    print("SCHEMA REGISTRY CLIENT SET UP")

    print("SETTING UP AVRO SERIALIZER")
    avro_serializer = AvroSerializer(schema_registry_client,
                                     schema_str)
    print("AVRO SERIALIZER SET UP")

    string_serializer = StringSerializer('utf_8')

    print("SETTING UP PRODUCER")
    producer = Producer(config)
    print("PRODUCER SET UP")


    states = ['MA', 'NH', 'MI', 'FL', 'CA', 'NY', 'IN', 'OH', 'MI', 'CA', 'RI', 'NJ', 'MS', 'MA', 'OH', 'MI', 'MN', 'ND', 'MT', 'MI']

    while True:


        id = random.randrange(1, 19)

        state_index = id - 1

        if random.randrange(1,5) == 3:
           state_index += 1

        fnol = {
          "claim_id": str(uuid.uuid4()),
          "account_id": id, 
          "loss_type": "ACCIDENT", 
          "date_of_loss": "2024-05-08",
          "submitted_at": time.time(),  
          "state_of_loss": states[state_index],
          "amount_of_loss": random.randrange(200, 10000),
          "police_report_uploaded": random.choice([True, False]),
          "pictures_needed": random.choice([True, False]),
          "pictures_uploaded": False
        }

        print("PRODUCING RECORD:")
        print(fnol)

        producer.produce(
          topic=topic,
          key=str(id),
          value=avro_serializer(fnol, SerializationContext(topic, MessageField.VALUE))
        )
        print("DONE")
        print("-----------------------------------")

        producer.flush()

        time.sleep(5)


def main():
  config = read_config()
  topic = "auto_fnol"

  produce(topic, config)

  


main()