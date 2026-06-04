package org.eclipse.edc.virtualized.dataplane.qcresult;

import org.eclipse.edc.runtime.metamodel.annotation.Extension;
import org.eclipse.edc.runtime.metamodel.annotation.Inject;
import org.eclipse.edc.runtime.metamodel.annotation.Provider;
import org.eclipse.edc.runtime.metamodel.annotation.Setting;
import org.eclipse.edc.spi.system.ServiceExtension;
import org.eclipse.edc.spi.system.ServiceExtensionContext;
import org.eclipse.edc.spi.types.TypeManager;
import org.eclipse.edc.sql.QueryExecutor;
import org.eclipse.edc.sql.bootstrapper.SqlSchemaBootstrapper;
import org.eclipse.edc.transaction.datasource.spi.DataSourceRegistry;
import org.eclipse.edc.transaction.spi.TransactionContext;
import org.eclipse.edc.virtualized.dataplane.qcresult.store.QcResultStore;
import org.eclipse.edc.virtualized.dataplane.qcresult.store.sql.SqlQcResultStore;

import static org.eclipse.edc.virtualized.dataplane.qcresult.QcResultSqlExtension.NAME;

@Extension(NAME)
public class QcResultSqlExtension implements ServiceExtension {
    public static final String NAME = "QC Result Sql Store Extension";

    @Setting(description = "The datasource to be used", defaultValue = DataSourceRegistry.DEFAULT_DATASOURCE, key = "edc.sql.store.qcresults.datasource")
    private String dataSourceName;

    @Inject
    private DataSourceRegistry dataSourceRegistry;
    @Inject
    private TransactionContext transactionContext;
    @Inject
    private TypeManager typeManager;
    @Inject
    private QueryExecutor queryExecutor;
    @Inject
    private SqlSchemaBootstrapper sqlSchemaBootstrapper;

    @Override
    public void initialize(ServiceExtensionContext context) {
        sqlSchemaBootstrapper.addStatementFromResource(dataSourceName, "qcresult-schema.sql");
    }

    @Provider
    public QcResultStore qcResultStore() {
        return new SqlQcResultStore(dataSourceRegistry, dataSourceName, transactionContext, typeManager.getMapper(), queryExecutor);
    }
}