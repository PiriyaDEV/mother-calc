import React, { useState, useEffect } from "react";

interface SettingsPopupProps {
  isOpen: boolean;
  settings: { vat: number; serviceCharge: number };
  setSettings: (settings: { vat: number; serviceCharge: number }) => void;
  onCancel: () => void;
}

const SettingsPopup: React.FC<SettingsPopupProps> = ({
  isOpen,
  settings,
  setSettings,
  onCancel,
}) => {
  const [tempSettings, setTempSettings] = useState(settings);

  // Update the tempSettings state if the settings prop changes
  useEffect(() => {
    setTempSettings(settings);
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
    (field: keyof typeof tempSettings) =>
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.target.value === "" ? "" : Number(e.target.value);
      setTempSettings({
        ...tempSettings,
        [field]: value,
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
                value={tempSettings.vat === 0 ? "" : tempSettings.vat}
                onChange={handleChange("vat")}
                placeholder="กรุณาใส่ VAT"
                className="input input-bordered w-full"
              />
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
                value={
                  tempSettings.serviceCharge === 0
                    ? ""
                    : tempSettings.serviceCharge
                }
                onChange={handleChange("serviceCharge")}
                placeholder="กรุณาใส่ Service Charge"
                className="input input-bordered w-full"
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
