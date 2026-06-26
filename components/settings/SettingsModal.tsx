"use client";

import { useState, useEffect } from "react";
import { Settings } from "@/lib/types";
import Modal from "@/components/ui/Modal";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Toggle from "@/components/ui/Toggle";

interface SettingsModalProps {
  isOpen: boolean;
  settings: Settings;
  onSave: (settings: Settings) => void;
  onClose: () => void;
  onReset: () => void;
}

export default function SettingsModal({
  isOpen,
  settings,
  onSave,
  onClose,
  onReset,
}: SettingsModalProps) {
  const [form, setForm] = useState({
    vat: settings.vat.toString(),
    serviceCharge: settings.serviceCharge.toString(),
    isVat: settings.isVat,
    isService: settings.isService,
  });
  const [confirmReset, setConfirmReset] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setForm({
        vat: settings.vat.toString(),
        serviceCharge: settings.serviceCharge.toString(),
        isVat: settings.isVat,
        isService: settings.isService,
      });
      setConfirmReset(false);
    }
  }, [isOpen, settings]);

  const handleSave = () => {
    const vat = parseFloat(form.vat) || 0;
    const serviceCharge = parseFloat(form.serviceCharge) || 0;
    onSave({ vat, serviceCharge, isVat: form.isVat, isService: form.isService });
    onClose();
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="ตั้งค่าเริ่มต้น">
      <div className="flex flex-col gap-5">
        {/* VAT */}
        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-700">VAT</p>
              <p className="text-xs text-gray-400">ภาษีมูลค่าเพิ่ม</p>
            </div>
            <Toggle
              checked={form.isVat}
              onChange={(v) => setForm((p) => ({ ...p, isVat: v }))}
            />
          </div>
          {form.isVat && (
            <Input
              label="อัตรา VAT (%)"
              type="number"
              value={form.vat}
              onChange={(e) => setForm((p) => ({ ...p, vat: e.target.value }))}
              placeholder="7"
              min="0"
              max="100"
              onKeyDown={(e) => ["e", "-", "+"].includes(e.key) && e.preventDefault()}
            />
          )}
        </div>

        <div className="h-px bg-gray-100" />

        {/* Service Charge */}
        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-700">Service Charge</p>
              <p className="text-xs text-gray-400">ค่าบริการ</p>
            </div>
            <Toggle
              checked={form.isService}
              onChange={(v) => setForm((p) => ({ ...p, isService: v }))}
            />
          </div>
          {form.isService && (
            <Input
              label="อัตรา Service Charge (%)"
              type="number"
              value={form.serviceCharge}
              onChange={(e) => setForm((p) => ({ ...p, serviceCharge: e.target.value }))}
              placeholder="10"
              min="0"
              max="100"
              onKeyDown={(e) => ["e", "-", "+"].includes(e.key) && e.preventDefault()}
            />
          )}
        </div>

        <div className="h-px bg-gray-100" />

        {/* Reset */}
        <div>
          <p className="text-xs text-gray-400 mb-2">⚠️ รีเซ็ตข้อมูลทั้งหมด (ไม่สามารถกู้คืนได้)</p>
          {!confirmReset ? (
            <Button
              variant="ghost"
              size="sm"
              className="text-red-500 hover:bg-red-50"
              onClick={() => setConfirmReset(true)}
            >
              ล้างข้อมูลทั้งหมด
            </Button>
          ) : (
            <div className="flex gap-2">
              <Button
                variant="danger"
                size="sm"
                onClick={() => {
                  onReset();
                  onClose();
                }}
              >
                ยืนยันล้างข้อมูล
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setConfirmReset(false)}
              >
                ยกเลิก
              </Button>
            </div>
          )}
        </div>

        {/* Actions */}
        <div className="flex gap-2 pt-1">
          <Button variant="secondary" fullWidth onClick={onClose}>
            ยกเลิก
          </Button>
          <Button fullWidth onClick={handleSave}>
            บันทึก
          </Button>
        </div>
      </div>
    </Modal>
  );
}
