package org.eclipse.edc.virtualized.dataplane.qcresult.store;

import org.eclipse.edc.virtualized.dataplane.qcresult.model.QcResult;
import java.util.List;

public interface QcResultStore {
    void store(QcResult result);
    List<QcResult> getAll();
}