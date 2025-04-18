import React, { useState, useEffect } from "react";
import "./styles.css";

export interface Settings {
  vat: number;
  serviceCharge: number;
  isVat: boolean;
  isService: boolean;
}

interface SettingsPopupProps {
  isOpen: boolean;
  settings: Settings;
  setSettings: (settings: Settings) => void;
  onCancel: () => void;
}

const SettingsPopup: React.FC<SettingsPopupProps> = ({
  isOpen,
  settings,
  setSettings,
  onCancel,
}) => {
  const [tempSettings, setTempSettings] = useState<Settings>({
    vat: settings.vat ?? 0,
    serviceCharge: settings.serviceCharge ?? 0,
    isVat: settings.isVat ?? false,
    isService: settings.isService ?? false,
  });

  useEffect(() => {
    setTempSettings({
      vat: settings.vat ?? 0,
      serviceCharge: settings.serviceCharge ?? 0,
      isVat: settings.isVat ?? false,
      isService: settings.isService ?? false,
    });
  }, [settings]);

  const handleSave = () => {
    setSettings(tempSettings);
    onCancel();
  };

  const handleCancel = () => {
    setTempSettings(settings);
    onCancel();
  };

  const handleChange =
    (field: keyof Pick<Settings, "vat" | "serviceCharge">) =>
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.target.value;
      setTempSettings((prev) => ({
        ...prev,
        [field]: value === "" ? 0 : Number(value),
      }));
    };

  const handleToggleChange =
    (field: "isVat" | "isService") =>
    (e: React.ChangeEvent<HTMLInputElement>) => {
      setTempSettings({
        ...tempSettings,
        [field]: e.target.checked,
      });
    };

  return (
    <>
      {isOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50"
          onClick={(e) => {
            if (e.target === e.currentTarget) {
              handleCancel();
            }
          }}
        >
          <div className="bg-base-100 p-6 rounded-xl shadow-lg w-96 m-4">
            <h3 className="font-bold text-lg text-center">ตั้งค่าเริ่มต้น</h3>

            <div className="pt-4">
              <p className="!text-[#4366f4] font-bold text-sm mb-2">
                เปิดใช้งาน VAT
              </p>
              <label>
                <input
                  className="toggle"
                  type="checkbox"
                  checked={tempSettings.isVat}
                  onChange={handleToggleChange("isVat")}
                />
                <span className="toggle-switch"></span>
              </label>
            </div>

            <div className="py-4">
              <p className="!text-[#4366f4] font-bold text-sm mb-2">VAT (%)</p>
              <input
                id="vat"
                type="number"
                onKeyDown={(e) => {
                  if (e.key === "-" || e.key === "e") {
                    e.preventDefault();
                  }
                }}
                value={tempSettings.vat.toString()}
                onChange={handleChange("vat")}
                placeholder="กรุณาใส่ VAT"
                className="input input-bordered w-full"
                disabled={!tempSettings.isVat}
              />
            </div>

            <div className="pt-4">
              <p className="!text-[#4366f4] font-bold text-sm mb-2">
                เปิดใช้งาน Service Charge
              </p>
              <label>
                <input
                  className="toggle"
                  type="checkbox"
                  checked={tempSettings.isService}
                  onChange={handleToggleChange("isService")}
                />
                <span className="toggle-switch"></span>
              </label>
            </div>

            <div className="py-4">
              <p className="!text-[#4366f4] font-bold text-sm mb-2">
                Service Charge (%)
              </p>
              <input
                id="serviceCharge"
                type="number"
                onKeyDown={(e) => {
                  if (e.key === "-" || e.key === "e") {
                    e.preventDefault();
                  }
                }}
                value={tempSettings.serviceCharge.toString()}
                onChange={handleChange("serviceCharge")}
                placeholder="กรุณาใส่ Service Charge"
                className="input input-bordered w-full"
                disabled={!tempSettings.isService}
              />
            </div>

            <div className="flex justify-between mt-4">
              <button
                className="btn bg-[#4366f4] btn-sm text-white w-full"
                onClick={handleSave}
              >
                บันทึก
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default SettingsPopup;
