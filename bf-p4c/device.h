/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#ifndef EXTENSIONS_BF_P4C_DEVICE_H_
#define EXTENSIONS_BF_P4C_DEVICE_H_

#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "phv/phv_spec.h"

class Device {
 public:
    /**
     * Initialize the global device context for the provided target - e.g.
     * "Tofino" or "JBay".
     *
     * Fatally asserts if the global device context was already initialized.
     *
     * This should be called as early as possible at startup, since the Device
     * singleton is available everywhere in the compiler.
     */
    static void init(cstring name);

    /**
     * Initialize the global device context for the provided target - e.g.
     * "Tofino" or "JBay".
     *
     * If the global device context was already initialized, it is replaced.
     * This will invalidate many data structures throughout the compiler; it's
     * the responsibility of the caller to choose a safe point to do this.
     * This is intended for use with unit tests.
     */
    static void reinitialize(cstring name);

    static const Device& get() {
       BUG_CHECK(instance_ != nullptr, "No device specified");
       return *instance_;
    }

    static cstring currentDevice() { return Device::get().name(); }

    static const PhvSpec& phvSpec() { return Device::get().getPhvSpec(); }

 protected:
    explicit Device(cstring name) : name_(name) {}

    cstring name() const { return name_; }

    virtual const PhvSpec& getPhvSpec() const = 0;

    cstring name_;

 private:
    static Device* instance_;
};


class TofinoDevice : public Device {
    const TofinoPhvSpec phv_;

 public:
    TofinoDevice() : Device("Tofino") {}

    const PhvSpec& getPhvSpec() const { return phv_; }
};

#if HAVE_JBAY
class JBayDevice : public Device {
    const JBayPhvSpec phv_;

 public:
    JBayDevice() : Device("JBay") {}

    const PhvSpec& getPhvSpec() const { return phv_; }
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_DEVICE_H_ */
