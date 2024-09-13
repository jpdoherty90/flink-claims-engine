import oracledb
import config
import time

def print_current_row(cursor: oracledb.Cursor, first_name: str = "Jahmyr") -> None:
    print(f"{first_name}'s current information")
    statement = "select * from CUSTOMERS where first_name = :1"
    cursor.execute(statement, [first_name])
    results = cursor.fetchall()
    for result in results:
        print(result)

def update_row(cursor: oracledb.Cursor,
               connection: oracledb.Connection,
               day: int,
               first_name: str = "Jahmyr",) -> None:
    date = "2024-04-" + str((day % 29) + 1)
    print("DATE:")
    print(date)
    statement = "update CUSTOMERS set policy_expiration_date = to_date('" + date + "', 'YYYY-MM-DD') where first_name = :1"
    print(f"increasing {first_name}'s policy expiration date by 1 day")
    cursor.execute(statement, [first_name])
    connection.commit()

if __name__=="__main__":

    with oracledb.connect(
        user="",
        password="c",
        dsn="<the-rds-url>/orcl",
        port=1521) as connection:
        
        cursor = connection.cursor()
        day = 0

        try:
            while True:
                day += 1
                print_current_row(cursor)
                update_row(cursor, connection, day)
                time.sleep(5)
        except KeyboardInterrupt:
            print("\nclosing")