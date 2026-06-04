package org.eclipse.edc.virtualized.dataplane.qcresult.api;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.edc.transaction.spi.TransactionContext;
import org.eclipse.edc.virtualized.dataplane.qcresult.model.QcResult;
import org.eclipse.edc.virtualized.dataplane.qcresult.store.QcResultStore;

import java.util.List;

@Path("qcresults")
@Produces(MediaType.APPLICATION_JSON)
public class QcResultInternalController {

    private final QcResultStore store;
    private final TransactionContext transactionContext;

    public QcResultInternalController(QcResultStore store, TransactionContext transactionContext) {
        this.store = store;
        this.transactionContext = transactionContext;
    }

    @GET
    public List<QcResult> getAll() {
        return transactionContext.execute(() -> store.getAll());
    }
}