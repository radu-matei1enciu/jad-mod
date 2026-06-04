package org.eclipse.edc.virtualized.dataplane.qcresult.store.sql;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.eclipse.edc.spi.EdcException;
import org.eclipse.edc.sql.QueryExecutor;
import org.eclipse.edc.sql.store.AbstractSqlStore;
import org.eclipse.edc.transaction.datasource.spi.DataSourceRegistry;
import org.eclipse.edc.transaction.spi.TransactionContext;
import org.eclipse.edc.virtualized.dataplane.qcresult.model.QcResult;
import org.eclipse.edc.virtualized.dataplane.qcresult.store.QcResultStore;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

public class SqlQcResultStore extends AbstractSqlStore implements QcResultStore {

    private static final String TABLE = "qc_result";

    public SqlQcResultStore(DataSourceRegistry dataSourceRegistry, String dataSourceName,
                            TransactionContext transactionContext, ObjectMapper objectMapper,
                            QueryExecutor queryExecutor) {
        super(dataSourceRegistry, dataSourceName, transactionContext, objectMapper, queryExecutor);
    }

    @Override
    public void store(QcResult result) {
        transactionContext.execute(() -> {
            try (var connection = getConnection()) {
                var stmt = """
                        INSERT INTO %s (id, batch_id, product, test, result, specification, status, approved_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                        ON CONFLICT (id) DO NOTHING
                        """.formatted(TABLE);
                queryExecutor.execute(connection, stmt,
                        result.id(),
                        result.batchId(),
                        result.product(),
                        result.test(),
                        result.result(),
                        result.specification(),
                        result.status(),
                        result.approvedAt()
                );
            } catch (SQLException e) {
                throw new EdcException(e);
            }
        });
    }

    @Override
    public List<QcResult> getAll() {
        return transactionContext.execute(() -> {
            try (var connection = getConnection()) {
                var stmt = "SELECT * FROM " + TABLE;
                return queryExecutor.query(connection, true, this::mapRow, stmt).toList();
            } catch (SQLException e) {
                throw new EdcException(e);
            }
        });
    }

    private QcResult mapRow(ResultSet rs) throws SQLException {
        return new QcResult(
                rs.getString("id"),
                rs.getString("batch_id"),
                rs.getString("product"),
                rs.getString("test"),
                rs.getString("result"),
                rs.getString("specification"),
                rs.getString("status"),
                rs.getString("approved_at")
        );
    }
}
