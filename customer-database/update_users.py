import oracledb
from pathlib import Path

def execute_file(connection: oracledb.Connection, sql_file: str) -> None:
    cursor = connection.cursor()
    with open(sql_file) as statements:
        for statement in statements:
            statement = statement.strip().rstrip(";")
            if statement.startswith("--") or not statement:
                continue
            print("\nexecuting statement:")
            print(f"{statement};")
            try:
                if "rdsadmin" in statement:
                    cursor.execute(f"{statement};")
                else:
                    cursor.execute(statement)
            except oracledb.DatabaseError as e:
                error, = e.args
                print(error.message)
                print("skipping\n")
    connection.commit()

if __name__=="__main__":

    sql_update_database = Path(__file__).absolute().with_name("update_policy_expiration.sql")
    with oracledb.connect(
        user="",
        password="",
        dsn="<rds-url/orcl",
        port=1521) as connection:

        print("Updating CUSTOMERS table")
        execute_file(connection, sql_update_database)
