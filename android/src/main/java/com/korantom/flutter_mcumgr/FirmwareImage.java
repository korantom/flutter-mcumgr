package com.korantom.flutter_mcumgr;

import java.util.HashMap;

import io.runtime.mcumgr.response.img.McuMgrImageStateResponse;

class FirmwareImage {

    final int slot;
    final String version;
    final byte[] hash;
    final String hashStr;
    final HashMap<String, Boolean> flags;

    FirmwareImage(int slot, String version, byte[] hash, String hashStr, HashMap<String, Boolean> flags) {
        this.slot = slot;
        this.version = version;
        this.hash = hash;
        this.hashStr = hashStr;
        this.flags = flags;
    }

    FirmwareImage(final McuMgrImageStateResponse.ImageSlot image) {
        this(image.slot,
                image.version, image.hash,
                StringUtils.toHex(image.hash),
                new HashMap<String, Boolean>() {{
                    put("active", image.active);
                    put("bootable", image.bootable);
                    put("confirmed", image.confirmed);
                    put("pending", image.pending);
                    put("permanent", image.permanent);

                }});
    }
}