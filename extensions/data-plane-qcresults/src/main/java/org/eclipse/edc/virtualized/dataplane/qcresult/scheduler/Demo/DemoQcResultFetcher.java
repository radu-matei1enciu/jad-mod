package org.eclipse.edc.virtualized.dataplane.qcresult.scheduler.demo;

import org.eclipse.edc.virtualized.dataplane.qcresult.model.QcResult;
import org.eclipse.edc.virtualized.dataplane.qcresult.scheduler.QcResultFetcher;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.UUID;

public class DemoQcResultFetcher implements QcResultFetcher {

    private static final Random RANDOM = new Random();

    private static final List<String> BATCHES = List.of(
            "BATCH-2026-001", "BATCH-2026-002", "BATCH-2026-003"
    );

    private static final List<String> PRODUCTS = List.of(
            "Product A", "Product B", "Product C"
    );

    private static final List<String[]> TESTS = List.of(
            // { testName, result, specification, status }
            new String[]{"Potency",   "98.7%",      "95-105%",      "PASS"},
            new String[]{"Purity",    "99.1%",      ">=98.0%",      "PASS"},
            new String[]{"Endotoxin", "0.04 EU/mL", "<=0.25 EU/mL", "PASS"},
            new String[]{"Assay",     "92.1%",      "95-105%",      "FAIL"},
            new String[]{"pH",        "7.2",        "6.8-7.4",      "PASS"},
            new String[]{"Sterility", "No growth",  "No growth",    "PASS"}
    );

    @Override
    public List<QcResult> fetch() {
        var batch   = pick(BATCHES);
        var product = pick(PRODUCTS);
        var approvedAt = Instant.now().toString();

        var shuffled = new ArrayList<>(TESTS);
        Collections.shuffle(shuffled, RANDOM);
        var selectedTests = shuffled.subList(0, 3);

        var results = new ArrayList<QcResult>();
        for (var test : selectedTests) {
            results.add(new QcResult(
                    "QC-" + UUID.randomUUID(),
                    batch,
                    product,
                    test[0],
                    test[1],
                    test[2],
                    test[3],
                    approvedAt
            ));
        }
        return results;
    }

    private static <T> T pick(List<T> list) {
        return list.get(RANDOM.nextInt(list.size()));
    }
}