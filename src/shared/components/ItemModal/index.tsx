import React from "react";
import Item from "@/shared/pages/Item";
import { ItemObj } from "@/app/lib/interface";

type ItemModalProps = {
  members: any[];
  itemArr:  ItemObj[];
  setItemArr: React.Dispatch<React.SetStateAction<ItemObj[]>>;
  setItemModalOpen: React.Dispatch<React.SetStateAction<boolean>>;
  editingItem?: ItemObj;
};

const ItemModal: React.FC<ItemModalProps> = ({
  members,
  itemArr,
  setItemArr,
  setItemModalOpen,
  editingItem,
}) => {
  const onBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      setItemModalOpen(false);
    }
  };

  return (
    <div className="modal modal-open !text-black" onClick={onBackdropClick}>
      <div className="modal-box">
        <Item
          members={members}
          itemArr={itemArr}
          setItemArr={setItemArr}
          setItemModalOpen={setItemModalOpen}
          editingItem={editingItem}
        />
      </div>
    </div>
  );
};

export default ItemModal;
