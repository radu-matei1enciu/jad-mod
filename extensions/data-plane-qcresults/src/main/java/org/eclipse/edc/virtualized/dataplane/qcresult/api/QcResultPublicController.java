package org.eclipse.edc.virtualized.dataplane.qcresult.api;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import org.eclipse.edc.spi.iam.ClaimToken;
import org.eclipse.edc.transaction.spi.TransactionContext;

import java.util.List;

import org.eclipse.edc.virtualized.dataplane.qcresult.store.QcResultStore;

import static jakarta.ws.rs.core.Response.Status.FORBIDDEN;
import static jakarta.ws.rs.core.Response.Status.UNAUTHORIZED;
import static org.eclipse.edc.api.authentication.filter.Constants.REQUEST_PROPERTY_CLAIMS;

@Path("qcresults")
public class QcResultPublicController {

    private final QcResultStore store;
    private final TransactionContext transactionContext;

    public QcResultPublicController(QcResultStore store, TransactionContext transactionContext) {
        this.store = store;
        this.transactionContext = transactionContext;
    }

    @GET
    public List<QcResult> getAll(@Context ContainerRequestContext requestContext) {
        return transactionContext.execute(() -> {
            checkAuth(requestContext);
            return store.getAll();
        });
    }

    private void checkAuth(ContainerRequestContext requestContext) {
        if (requestContext == null) {
            throw new WebApplicationException(UNAUTHORIZED);
        }
        var claims = requestContext.getProperty(REQUEST_PROPERTY_CLAIMS);
        if (!(claims instanceof ClaimToken)) {
            throw new WebApplicationException(FORBIDDEN);
        }
    }
}