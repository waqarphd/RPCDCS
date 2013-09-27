SRCS = $(shell ls *.IN )
SQLS = $(subst 3.02.sql.IN,3.02.sql, ${SRCS}) fwConfigurationDB_createSchema.sql
TEMPLS = $(shell ls *.SQL )

all: ${SQLS}


%.sql:%.sql.IN ${TEMPLS}
	cpp -P -C -traditional $< >$@

clean:
	rm *.sql