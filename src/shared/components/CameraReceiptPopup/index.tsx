"use client";

import { ItemObj, MemberObj } from "@/app/lib/interface";
import { useRef, useState, useCallback, useEffect } from "react";
import {
  FaCamera,
  FaTimes,
  FaCrop,
  FaCheck,
  FaRedo,
  FaTrash,
  FaPlus,
} from "react-icons/fa";

interface CameraReceiptPopupProps {
  isOpen: boolean;
  members: MemberObj[];
  onClose: () => void;
  onConfirm: (items: ItemObj[]) => void;
}

type Stage = "camera" | "crop" | "preview" | "processing" | "confirm";

export default function CameraReceiptPopup({
  isOpen,
  members,
  onClose,
  onConfirm,
}: CameraReceiptPopupProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const cropCanvasRef = useRef<HTMLCanvasElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const membersRef = useRef<MemberObj[]>(members);

  useEffect(() => {
    membersRef.current = members;
  }, [members]);

  const [stage, setStage] = useState<Stage>("camera");
  const [capturedImage, setCapturedImage] = useState<string | null>(null);
  const [grayscaleImage, setGrayscaleImage] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pendingItems, setPendingItems] = useState<ItemObj[]>([]);

  const [cropStart, setCropStart] = useState<{ x: number; y: number } | null>(null);
  const [cropRect, setCropRect] = useState<{
    x: number;
    y: number;
    w: number;
    h: number;
  } | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const overlayRef = useRef<HTMLDivElement>(null);

  // stopCamera: always clears srcObject so the camera LED turns off
  const stopCamera = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
  }, []);

  // handleRetake: force-stops camera, wipes ALL state, then transitions to
  // "camera" stage which triggers the useEffect below to restart the camera
  const handleRetake = useCallback(() => {
    stopCamera();
    setCapturedImage(null);
    setGrayscaleImage(null);
    setCropRect(null);
    setCropStart(null);
    setIsDragging(false);
    setError(null);
    setPendingItems([]);
    setIsLoading(false);
    setStage("camera");
  }, [stopCamera]);

  // handleClose: force-stop camera first, then call parent onClose
  const handleClose = useCallback(() => {
    stopCamera();
    onClose();
  }, [stopCamera, onClose]);

  // startCamera: always kills any lingering stream before requesting a new one
  const startCamera = useCallback(async () => {
    setError(null);
    stopCamera();
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: { ideal: "environment" },
          width: { ideal: 1080 },
          height: { ideal: 1920 },
        },
        audio: false,
      });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        await videoRef.current.play();
      }
    } catch (err) {
      setError("ไม่สามารถเข้าถึงกล้องได้ กรุณาอนุญาตการใช้งานกล้อง");
      console.error("Camera error:", err);
    }
  }, [stopCamera]);

  useEffect(() => {
    if (isOpen && stage === "camera") startCamera();
    return () => {
      if (!isOpen) stopCamera();
    };
  }, [isOpen, stage, startCamera, stopCamera]);

  useEffect(() => {
    if (!isOpen) {
      stopCamera();
      setStage("camera");
      setCapturedImage(null);
      setGrayscaleImage(null);
      setCropRect(null);
      setError(null);
      setPendingItems([]);
    }
  }, [isOpen, stopCamera]);

  const capturePhoto = () => {
    const video = videoRef.current;
    const canvas = canvasRef.current;
    if (!video || !canvas) return;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.drawImage(video, 0, 0);
    setCapturedImage(canvas.toDataURL("image/jpeg", 0.95));
    stopCamera();
    setStage("crop");
  };

  const toGrayscale = (imageDataUrl: string): Promise<string> =>
    new Promise((resolve) => {
      const img = new Image();
      img.onload = () => {
        const off = document.createElement("canvas");
        off.width = img.width;
        off.height = img.height;
        const ctx = off.getContext("2d")!;
        ctx.drawImage(img, 0, 0);
        const id = ctx.getImageData(0, 0, off.width, off.height);
        for (let i = 0; i < id.data.length; i += 4) {
          const g = Math.round(
            0.299 * id.data[i] +
              0.587 * id.data[i + 1] +
              0.114 * id.data[i + 2],
          );
          id.data[i] = id.data[i + 1] = id.data[i + 2] = g;
        }
        ctx.putImageData(id, 0, 0);
        resolve(off.toDataURL("image/jpeg", 0.9));
      };
      img.src = imageDataUrl;
    });

  const applyCrop = async () => {
    if (!capturedImage) return;
    setIsLoading(true);
    const img = new Image();
    img.onload = async () => {
      const off = document.createElement("canvas");
      let sx = 0,
        sy = 0,
        sw = img.width,
        sh = img.height;

      if (cropRect && overlayRef.current) {
        const r = overlayRef.current.getBoundingClientRect();
        const containerW = r.width;
        const containerH = r.height;
        const imgAspect = img.width / img.height;
        const containerAspect = containerW / containerH;

        let renderedW: number,
          renderedH: number,
          offsetX: number,
          offsetY: number;
        if (imgAspect > containerAspect) {
          renderedW = containerW;
          renderedH = containerW / imgAspect;
          offsetX = 0;
          offsetY = (containerH - renderedH) / 2;
        } else {
          renderedH = containerH;
          renderedW = containerH * imgAspect;
          offsetX = (containerW - renderedW) / 2;
          offsetY = 0;
        }

        const scaleX = img.width / renderedW;
        const scaleY = img.height / renderedH;

        sx = (cropRect.x - offsetX) * scaleX;
        sy = (cropRect.y - offsetY) * scaleY;
        sw = cropRect.w * scaleX;
        sh = cropRect.h * scaleY;

        sx = Math.max(0, sx);
        sy = Math.max(0, sy);
        sw = Math.min(sw, img.width - sx);
        sh = Math.min(sh, img.height - sy);
      }

      off.width = sw;
      off.height = sh;
      off.getContext("2d")!.drawImage(img, sx, sy, sw, sh, 0, 0, sw, sh);
      const gray = await toGrayscale(off.toDataURL("image/jpeg", 0.95));
      setGrayscaleImage(gray);
      setIsLoading(false);
      setStage("preview");
    };
    img.src = capturedImage;
  };

  const parseLine = (line: string): ItemObj | null => {
    const cleaned = line
      .replace(/[^\u0E00-\u0E7F\u4E00-\u9FFFa-zA-Z0-9\s.\-]/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    const match = cleaned.match(/^(.+?)\s+(\d{1,6}(?:\.\d{1,2})?)\s*$/);
    if (!match) return null;
    const itemName = match[1].trim();
    const price = parseFloat(match[2]);
    if (!itemName || itemName.length < 2 || isNaN(price) || price <= 0)
      return null;
    const currentMembers = membersRef.current;
    const firstMember = currentMembers[0] ?? null;
    return {
      itemName,
      paidBy: firstMember?.name ?? "",
      price,
      vatRate: undefined,
      serviceChargeRate: undefined,
      selectedMembers: firstMember ? [{ ...firstMember, customPaid: 0 }] : [],
      isEqualSplit: true,
    };
  };

  const handleConfirm = async () => {
    if (!grayscaleImage) return;
    setIsLoading(true);
    stopCamera();
    setStage("processing");
    try {
      const Tesseract = (await import("tesseract.js")).default;
      const result = await Tesseract.recognize(grayscaleImage, "tha+eng", {
        logger: (m) => console.log("[Tesseract]", m),
      });
      const rawText = result.data.text;
      console.log("OCR raw text:", rawText);

      const lines = rawText
        .split("\n")
        .map((l: string) => l.trim())
        .filter(Boolean);
      const items: ItemObj[] = lines
        .map(parseLine)
        .filter((i): i is ItemObj => i !== null);
      console.log("parsed items:", items);

      if (items.length === 0) {
        setError("ไม่พบรายการในใบเสร็จ กรุณาตัดรูปใหม่หรือเพิ่มความสว่าง");
        setStage("preview");
        return;
      }
      setPendingItems(items);
      setStage("confirm");
    } catch (err) {
      console.error("handleConfirm error:", err);
      setError("OCR ล้มเหลว: " + err);
      setStage("preview");
    } finally {
      setIsLoading(false);
    }
  };

  const handleFinalConfirm = () => {
    const invalid = pendingItems.some(
      (item) => !item.itemName.trim() || !item.price || item.price <= 0,
    );
    if (invalid) {
      setError("กรุณากรอกชื่อและราคาให้ครบทุกรายการ");
      return;
    }
    setError(null);
    onConfirm(pendingItems);
    onClose();
  };

  const removeItem = (index: number) => {
    setPendingItems((prev) => prev.filter((_, i) => i !== index));
  };

  const updateItem = (
    index: number,
    field: "itemName" | "price",
    value: string,
  ) => {
    setPendingItems((prev) =>
      prev.map((item, i) => {
        if (i !== index) return item;
        if (field === "price") {
          const price = parseFloat(value);
          return { ...item, price: isNaN(price) ? 0 : price };
        }
        return { ...item, itemName: value };
      }),
    );
  };

  const addEmptyItem = () => {
    const currentMembers = membersRef.current;
    const firstMember = currentMembers[0] ?? null;
    setPendingItems((prev) => [
      ...prev,
      {
        itemName: "",
        paidBy: firstMember?.name ?? "",
        price: 0,
        vatRate: undefined,
        serviceChargeRate: undefined,
        selectedMembers: firstMember ? [{ ...firstMember, customPaid: 0 }] : [],
        isEqualSplit: true,
      },
    ]);
  };

  const getRelativePos = (
    e: React.MouseEvent | React.TouchEvent,
    el: HTMLElement,
  ) => {
    const rect = el.getBoundingClientRect();
    const clientX = "touches" in e ? e.touches[0].clientX : e.clientX;
    const clientY = "touches" in e ? e.touches[0].clientY : e.clientY;
    return {
      x: Math.max(0, Math.min(clientX - rect.left, rect.width)),
      y: Math.max(0, Math.min(clientY - rect.top, rect.height)),
    };
  };
  const handleCropStart = (e: React.MouseEvent | React.TouchEvent) => {
    if (!overlayRef.current) return;
    setCropStart(getRelativePos(e, overlayRef.current));
    setCropRect(null);
    setIsDragging(true);
  };
  const handleCropMove = (e: React.MouseEvent | React.TouchEvent) => {
    if (!isDragging || !cropStart || !overlayRef.current) return;
    const pos = getRelativePos(e, overlayRef.current);
    setCropRect({
      x: Math.min(cropStart.x, pos.x),
      y: Math.min(cropStart.y, pos.y),
      w: Math.abs(pos.x - cropStart.x),
      h: Math.abs(pos.y - cropStart.y),
    });
  };
  const handleCropEnd = () => setIsDragging(false);

  const stageLabel: Record<Stage, string> = {
    camera: "จัดตำแหน่งใบเสร็จแล้วกดถ่าย",
    crop: "ลากเพื่อเลือกพื้นที่ที่ต้องการ",
    preview: "ตรวจสอบภาพก่อนอ่าน",
    processing: "กำลังประมวลผล...",
    confirm: "ตรวจสอบรายการที่พบ",
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[200] flex items-end sm:items-center justify-center bg-black/40 backdrop-blur-sm">
      <div
        className="relative bg-white rounded-t-3xl sm:rounded-2xl shadow-2xl w-full sm:max-w-[450px] flex flex-col border border-gray-100"
        style={{ maxHeight: "92dvh" }}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full bg-[#4366f4] flex items-center justify-center">
              <FaCamera className="text-white text-sm" />
            </div>
            <div>
              <h2 className="text-gray-800 font-bold text-sm">ถ่ายใบเสร็จ</h2>
              <p className="text-gray-400 text-xs">{stageLabel[stage]}</p>
            </div>
          </div>
          {/* Close button: force-stops camera before closing */}
          <button
            onClick={handleClose}
            className="text-gray-400 hover:text-gray-600 transition-colors p-1"
          >
            <FaTimes className="text-lg" />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-hidden flex flex-col">
          {error && (
            <div className="mx-4 mt-4 p-3 bg-red-50 border border-red-200 rounded-xl text-red-500 text-sm text-center">
              {error}
            </div>
          )}

          {/* CAMERA */}
          {stage === "camera" && (
            <div className="flex flex-col flex-1">
              <div className="relative bg-gray-900 overflow-hidden flex items-center justify-center">
                <div
                  className="relative w-full"
                  style={{ aspectRatio: "3/4", maxHeight: "60dvh" }}
                >
                  <video
                    ref={videoRef}
                    autoPlay
                    playsInline
                    muted
                    className="absolute inset-0 w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 pointer-events-none flex items-center justify-center">
                    <div
                      className="relative border-2 border-dashed border-white/50 rounded-lg"
                      style={{ width: "72%", height: "88%" }}
                    >
                      <div className="absolute top-0 left-0 w-5 h-5 border-t-2 border-l-2 border-[#4366f4] rounded-tl-lg -translate-x-0.5 -translate-y-0.5" />
                      <div className="absolute top-0 right-0 w-5 h-5 border-t-2 border-r-2 border-[#4366f4] rounded-tr-lg translate-x-0.5 -translate-y-0.5" />
                      <div className="absolute bottom-0 left-0 w-5 h-5 border-b-2 border-l-2 border-[#4366f4] rounded-bl-lg -translate-x-0.5 translate-y-0.5" />
                      <div className="absolute bottom-0 right-0 w-5 h-5 border-b-2 border-r-2 border-[#4366f4] rounded-br-lg translate-x-0.5 translate-y-0.5" />
                    </div>
                  </div>
                </div>
              </div>
              <div className="px-5 py-5 flex justify-center bg-white">
                <button
                  onClick={capturePhoto}
                  className="w-16 h-16 rounded-full bg-white border-4 border-[#4366f4] flex items-center justify-center shadow-lg active:scale-95 transition-transform"
                >
                  <div className="w-11 h-11 rounded-full bg-[#4366f4]" />
                </button>
              </div>
            </div>
          )}

          {/* CROP */}
          {stage === "crop" && capturedImage && (
            <div className="flex flex-col flex-1">
              <div className="bg-gray-900 overflow-hidden flex items-center justify-center">
                <div
                  className="relative w-full select-none"
                  style={{
                    aspectRatio: "3/4",
                    maxHeight: "60dvh",
                    cursor: "crosshair",
                  }}
                  ref={overlayRef}
                  onMouseDown={handleCropStart}
                  onMouseMove={handleCropMove}
                  onMouseUp={handleCropEnd}
                  onMouseLeave={handleCropEnd}
                  onTouchStart={handleCropStart}
                  onTouchMove={handleCropMove}
                  onTouchEnd={handleCropEnd}
                >
                  <img
                    src={capturedImage}
                    alt="captured"
                    className="absolute inset-0 w-full h-full object-contain pointer-events-none"
                    draggable={false}
                  />
                  {cropRect && cropRect.w > 5 && cropRect.h > 5 && (
                    <>
                      <div className="absolute inset-0 bg-black/50 pointer-events-none" />
                      <div
                        className="absolute border-2 border-[#4366f4] pointer-events-none"
                        style={{
                          left: cropRect.x,
                          top: cropRect.y,
                          width: cropRect.w,
                          height: cropRect.h,
                          background: "transparent",
                          boxShadow: "0 0 0 9999px rgba(0,0,0,0.5)",
                        }}
                      >
                        {[
                          ["top-0 left-0", "-translate-x-1/2 -translate-y-1/2"],
                          ["top-0 right-0", "translate-x-1/2 -translate-y-1/2"],
                          ["bottom-0 left-0", "-translate-x-1/2 translate-y-1/2"],
                          ["bottom-0 right-0", "translate-x-1/2 translate-y-1/2"],
                        ].map(([pos, tr], i) => (
                          <div
                            key={i}
                            className={`absolute ${pos} w-3 h-3 bg-[#4366f4] rounded-full transform ${tr}`}
                          />
                        ))}
                      </div>
                    </>
                  )}
                  {!cropRect && (
                    <div className="absolute inset-0 flex items-center justify-center pointer-events-none opacity-10">
                      <p className="text-white text-sm bg-white px-3 py-1.5 rounded-full">
                        ลากเพื่อเลือกพื้นที่
                      </p>
                    </div>
                  )}
                </div>
              </div>
              <div className="px-5 py-4 flex gap-3 bg-white">
                <button
                  onClick={handleRetake}
                  className="flex-1 py-3 rounded-xl border border-gray-200 text-gray-500 text-sm flex items-center justify-center gap-2 hover:bg-gray-50 transition-colors"
                >
                  <FaRedo className="text-xs" /> ถ่ายใหม่
                </button>
                <button
                  onClick={applyCrop}
                  disabled={isLoading}
                  className="flex-1 py-3 rounded-xl bg-[#4366f4] text-white text-sm font-bold flex items-center justify-center gap-2 hover:bg-[#3355e0] transition-colors disabled:opacity-50"
                >
                  {isLoading ? (
                    <span className="inline-block w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  ) : (
                    <>
                      <FaCrop className="text-xs" /> ยืนยันการตัด
                    </>
                  )}
                </button>
              </div>
            </div>
          )}

          {/* PROCESSING */}
          {stage === "processing" && (
            <div className="flex flex-col flex-1 items-center justify-center gap-4 py-16 bg-white">
              <div className="w-12 h-12 border-4 border-gray-100 border-t-[#4366f4] rounded-full animate-spin" />
              <p className="text-gray-600 text-sm font-medium">
                กำลังอ่านใบเสร็จ...
              </p>
              <p className="text-gray-400 text-xs">
                Tesseract กำลังวิเคราะห์รายการ
              </p>
            </div>
          )}

          {/* PREVIEW */}
          {stage === "preview" && grayscaleImage && (
            <div className="flex flex-col flex-1">
              <div
                className="flex-1 bg-gray-50 flex items-center justify-center overflow-hidden border-b border-gray-100"
                style={{ minHeight: 280 }}
              >
                <img
                  src={grayscaleImage}
                  alt="grayscale receipt"
                  className="w-full h-full object-contain"
                  style={{ maxHeight: 380 }}
                />
              </div>
              <div className="px-5 py-3 bg-gray-50 border-b border-gray-100 text-center">
                <p className="text-gray-400 text-xs">
                  ภาพ Grayscale พร้อมสำหรับการอ่าน OCR
                </p>
              </div>
              <div className="px-5 py-4 flex gap-3 bg-white">
                <button
                  onClick={handleRetake}
                  className="flex-1 py-3 rounded-xl border border-gray-200 text-gray-500 text-sm flex items-center justify-center gap-2 hover:bg-gray-50 transition-colors"
                >
                  <FaRedo className="text-xs" /> ถ่ายใหม่
                </button>
                <button
                  onClick={() => {
                    setGrayscaleImage(null);
                    setError(null);
                    setStage("crop");
                  }}
                  className="flex-1 py-3 rounded-xl border border-[#4366f4] text-[#4366f4] text-sm flex items-center justify-center gap-2 hover:bg-blue-50 transition-colors"
                >
                  <FaCrop className="text-xs" /> ตัดใหม่
                </button>
                <button
                  onClick={handleConfirm}
                  disabled={isLoading}
                  className="flex-1 py-3 rounded-xl bg-[#4366f4] text-white text-sm font-bold flex items-center justify-center gap-2 hover:bg-[#3355e0] transition-colors disabled:opacity-60"
                >
                  {isLoading ? (
                    <span className="inline-block w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  ) : (
                    <>
                      <FaCheck className="text-xs" /> อ่านใบเสร็จ
                    </>
                  )}
                </button>
              </div>
            </div>
          )}

          {/* CONFIRM LIST */}
          {stage === "confirm" && (
            <div className="flex flex-col flex-1 overflow-hidden">
              <div className="px-5 pt-4 pb-2 flex items-center justify-between">
                <p className="text-gray-700 font-semibold text-sm">
                  พบ {pendingItems.length} รายการ
                </p>
                <p className="text-gray-400 text-xs">
                  กด 🗑 เพื่อลบรายการที่ไม่ต้องการ
                </p>
              </div>

              <div className="flex-1 overflow-y-auto px-5 pb-2 flex flex-col gap-2">
                {pendingItems.length === 0 && (
                  <div className="flex items-center justify-center py-6">
                    <p className="text-gray-400 text-sm">ยังไม่มีรายการ</p>
                  </div>
                )}
                {pendingItems.map((item, idx) => (
                  <div
                    key={idx}
                    className="flex items-center gap-2 bg-gray-50 border border-gray-100 rounded-xl px-3 py-2"
                  >
                    <input
                      type="text"
                      value={item.itemName}
                      onChange={(e) =>
                        updateItem(idx, "itemName", e.target.value)
                      }
                      placeholder="ชื่อรายการ"
                      className={`flex-1 min-w-0 text-sm text-gray-800 bg-transparent border-b outline-none py-1 px-0 focus:border-[#4366f4] ${!item.itemName.trim() ? "border-red-400 placeholder-red-300" : "border-gray-200"}`}
                    />
                    <input
                      type="number"
                      value={item.price || ""}
                      onChange={(e) => updateItem(idx, "price", e.target.value)}
                      placeholder="0"
                      className={`w-20 text-sm text-right font-bold bg-transparent border-b outline-none py-1 px-0 focus:border-[#4366f4] ${!item.price || item.price <= 0 ? "border-red-400 text-red-400 placeholder-red-300" : "border-gray-200 text-[#4366f4]"}`}
                    />
                    <span className="text-gray-400 text-xs shrink-0">฿</span>
                    <button
                      onClick={() => removeItem(idx)}
                      className="w-7 h-7 flex items-center justify-center rounded-lg text-red-400 hover:bg-red-50 hover:text-red-500 transition-colors shrink-0"
                    >
                      <FaTrash className="text-xs" />
                    </button>
                  </div>
                ))}
                <button
                  onClick={addEmptyItem}
                  className="w-full py-2.5 rounded-xl border-2 border-dashed border-gray-200 text-gray-400 text-sm flex items-center justify-center gap-2 hover:border-[#4366f4] hover:text-[#4366f4] transition-colors mt-1"
                >
                  <FaPlus className="text-xs" /> เพิ่มรายการ
                </button>
              </div>

              <div className="px-5 py-4 flex gap-3 bg-white border-t border-gray-100">
                <button
                  onClick={handleRetake}
                  className="flex-1 py-3 rounded-xl border border-gray-200 text-gray-500 text-sm flex items-center justify-center gap-2 hover:bg-gray-50 transition-colors"
                >
                  <FaRedo className="text-xs" /> ถ่ายใหม่
                </button>
                <button
                  onClick={handleFinalConfirm}
                  disabled={pendingItems.length === 0}
                  className="flex-1 py-3 rounded-xl bg-[#4366f4] text-white text-sm font-bold flex items-center justify-center gap-2 hover:bg-[#3355e0] transition-colors disabled:opacity-40"
                >
                  <FaCheck className="text-xs" /> เพิ่ม {pendingItems.length}{" "}
                  รายการ
                </button>
              </div>
            </div>
          )}
        </div>

        <canvas ref={canvasRef} className="hidden" />
        <canvas ref={cropCanvasRef} className="hidden" />
      </div>
    </div>
  );
}